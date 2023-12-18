//
//  PageLinkProvider.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2023-12-18.
//

import Foundation
import CoreData

final class PageLinkProviderModel: NSObject, ObservableObject {
    private let isBrowsePageProvider: Bool
    @MainActor
    @Published
    var runners: [DBRunner] = []

    @MainActor
    @Published
    var links: [String: [DSKCommon.PageLinkLabel]] = [:]

    @MainActor
    @Published
    var pending: [String: LinkProviderPendingState] = [:]

    @MainActor
    var runnersPendingSetup: [DBRunner] {
        runners.filter { pending.keys.contains($0.id) }
    }
    
    private let fetchController: NSFetchedResultsController<CDRunner>

    @MainActor
    @Published
    var selectedRunnerRequiringSetup: DBRunner?
    
    @MainActor
    @Published
    var selectedRunnerRequiringAuth: DBRunner?

    init(isForBrowsePage: Bool) {
        isBrowsePageProvider = isForBrowsePage
        fetchController = NSFetchedResultsController(fetchRequest: CDRunner.fetchAllRequest(),
                                                     managedObjectContext: CDManager.shared.context,
                                                     sectionNameKeyPath: nil,
                                                     cacheName: nil)
        super.init()
        fetchController.delegate = self
    }

    func getLinkProviders() async -> [AnyRunner] {
        let ids = await runners.filter {
            isBrowsePageProvider ? $0.intents.browsePageLinkProvider : $0.intents.libraryPageLinkProvider
            }
            .map(\.id)

        let results = await withTaskGroup(of: AnyRunner?.self) { group in

            for id in ids {
                group.addTask {
                    await DSK.shared.getRunner(id)
                }
            }

            var out: [AnyRunner] = []
            for await result in group {
                guard let result else { continue }
                if let result = result as? AnyContentTracker, !result.intents.advancedTracker {
                    Logger.shared.warn("Tracker has Page Provider Intent but does not implement the AdvancedTracker Intent", result.id)
                    continue
                }
                out.append(result)
            }

            return out
        }

        return results
    }

    func getPageLinks() async {
        await MainActor.run {
            links.removeAll()
            pending.removeAll()
        }
        let runners = await getLinkProviders()
        await withTaskGroup(of: Void.self) { group in
            for runner in runners {
                group.addTask {
                    await self.load(for: runner)
                }
            }
        }
    }

    func load(for runner: AnyRunner) async {
        if isBrowsePageProvider {
            guard runner.intents.browsePageLinkProvider else { return }
        } else {
            guard runner.intents.libraryPageLinkProvider else { return }
        }
        do {
            if runner.intents.requiresSetup {
                guard try await runner.isRunnerSetup().state else {
                    Task { @MainActor in
                        await animate { [weak self] in
                            self?.pending[runner.id] = .setup
                        }
                    }
                    return
                }
            }

            if let runner = runner as? AnyContentSource, runner.config?.requiresAuthenticationToAccessContent ?? false {
                guard runner.intents.authenticatable && runner.intents.authenticationMethod != .unknown else {
                    Logger.shared.warn("Runner has requested authentication to display content but has not implemented the required authentication methods.", runner.id)
                    return
                }
                guard let _ = try await runner.getAuthenticatedUser() else {
                    Task { @MainActor in
                        await animate { [weak self] in
                            self?.pending[runner.id] = .authentication
                        }
                    }
                    return
                }
            }
            let pageLinks = try await isBrowsePageProvider ? runner.getBrowsePageLinks() : runner.getLibraryPageLinks()
            guard !pageLinks.isEmpty else { return }

            Task { @MainActor in
                await animate { [weak self] in
                    self?.links.updateValue(pageLinks, forKey: runner.id)
                }
            }
        } catch {
            Logger.shared.error(error, runner.id)
        }
    }

    nonisolated
    func reload() {
        Task {
            await MainActor.run { [isBrowsePageProvider] in
                let manager = StateManager.shared
                isBrowsePageProvider ? manager.libraryUpdateRunnerPageLinks.send() : manager.browseUpdateRunnerPageLinks.send()
            }
        }
    }
}



extension PageLinkProviderModel: NSFetchedResultsControllerDelegate {
    func fetch() {
        do {
            try fetchController.performFetch()
            let result = fetchController.fetchedObjects ?? []
            let items = result.map({ $0.toDB() })
            Task  { @MainActor in
                runners = items
            }
        } catch {
            Logger.shared.error(error)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let result = controller.fetchedObjects as? [CDRunner] else  {
            return
        }
        
        let items = result.map({ $0.toDB() })
        Task  { @MainActor in
            runners = items
        } 
    }
}
