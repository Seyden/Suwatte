//
//  BrowseView.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2022-03-27.
//

import RealmSwift
import SwiftUI

struct BrowseView: View {
    @StateObject private var model = PageLinkProviderModel(isForBrowsePage: true)
    @State var noListInstalled = false
    @State var presentOnboarding = false
    @State var isVisible = false
    @State var hasLoaded = false
    @State var hasCheckedForRunnerUpdates = false
    @State var runnersWithUpdates: [DBRunner] = []
    @State var presentUpdatesView = false
    var body: some View {
        SmartNavigationView {
            List {
                if noListInstalled {
                    NoListInstalledView
                        .transition(.opacity)
                }
                PendingSetupView()
                InstalledSourcesSection
                InstalledTrackersSection
                PageLinks
            }
            .headerProminence(.increased)
            .listStyle(.insetGrouped)
            .navigationBarTitle("Browse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    NavigationLink {
                        SearchView()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentUpdatesView.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .opacity(runnersWithUpdates.isEmpty ? 0 : 1)
                }
            }
            .environmentObject(model)
            .refreshable {
                // FIXME: Refresh

            }
            .task {
                await checkForRunnerUpdates()
            }
            .fullScreenCover(item: $model.selectedRunnerRequiringSetup, onDismiss: model.reload, content: { runnerOBJ in
                SmartNavigationView {
                    LoadableRunnerView(runnerID: runnerOBJ.id) { runner in
                        DSKLoadableForm(runner: runner, context: .setup(closeOnSuccess: true))
                    }
                    .navigationTitle("\(runnerOBJ.name) Setup")
                    .closeButton()
                }
            })
            .fullScreenCover(item: $model.selectedRunnerRequiringAuth, onDismiss: model.reload, content: { runnerOBJ in
                SmartNavigationView {
                    LoadableRunnerView(runnerID: runnerOBJ.id) { runner in
                        List {
                            DSKAuthView(model: .init(runner: runner))
                        }
                    }
                    .navigationTitle("Sign In to \(runnerOBJ.name)")
                    .navigationBarTitleDisplayMode(.inline)
                    .closeButton(title: "Done")
                }
            })
            .sheet(isPresented: $presentUpdatesView, content: {
                SmartNavigationView {
                    UpdateRunnersView(data: $runnersWithUpdates)
                }
            })
            .animation(.default, value: model.links)
            .animation(.default, value: model.runners)
            .animation(.default, value: model.pending)
            .animation(.default, value: noListInstalled)
        }
        .task {
            guard !hasLoaded else { return }
            model.fetch()
            checkLists()
            hasLoaded = true
        }
        .onReceive(StateManager.shared.browseUpdateRunnerPageLinks) { _ in
            hasLoaded = false
        }
        .fullScreenCover(isPresented: $presentOnboarding, onDismiss: checkLists) {
            OnboardingView()
        }
    }

    func checkLists() {
        Task {
            noListInstalled = CDRunnerList.noListInstalled()
        }
    }

    func checkForRunnerUpdates() async {
        guard !hasCheckedForRunnerUpdates else { return }
        let data = await RealmActor.shared().getRunnerUpdates()
//        await animate {
//            runnersWithUpdates = data
//        }
        hasCheckedForRunnerUpdates = true
    }
}

// MARK: Sources

extension BrowseView {
    var sources: [DBRunner] {
        model.runners
            .filter { $0.environment == .source && !$0.intents.browsePageLinkProvider }
    }

    @ViewBuilder
    var InstalledSourcesSection: some View {
        if !sources.isEmpty {
            Section {
                ForEach(sources) { runner in
                    NavigationLink {
                        SourceLandingPage(sourceID: runner.id)
                            .navigationBarTitle(runner.name)
                    } label: {
                        HStack(spacing: 15) {
                            STTThumbView(url: URL(string: runner.thumbnail))
                                .frame(width: 40, height: 40)
                                .cornerRadius(5)
                            Text(runner.name)
                                .font(.headline)
                            Spacer()
                        }
                    }
                }
            } header: {
                Text("Sources")
            }
        }
    }
}

// MARK: Trackers

extension BrowseView {
    var trackers: [DBRunner] {
        model.runners
            .filter { $0.environment == .tracker && !$0.intents.browsePageLinkProvider }
    }

    @ViewBuilder
    var InstalledTrackersSection: some View {
        if !trackers.isEmpty {
            Section {
                ForEach(trackers) { runner in
                    NavigationLink {
                        TrackerLandingPage(trackerID: runner.id)
                            .navigationBarTitle(runner.name)

                    } label: {
                        HStack(spacing: 15) {
                            STTThumbView(url: URL(string: runner.thumbnail))
                                .frame(width: 40, height: 40)
                                .cornerRadius(5)
                            Text(runner.name)
                            Spacer()
                        }
                    }
                }
            } header: {
                Text("Trackers")
            }
        }
    }
}

// MARK: - Page Links

extension BrowseView {
    var linkProviders: [DBRunner] {
        model
            .runners
            .filter { $0.intents.browsePageLinkProvider }
            .filter { model.links[$0.id] != nil }
    }

    var PageLinks: some View {
        Group {
            ForEach(linkProviders) { object in
                let id = object.id
                if let links = model.links[id] {
                    PageLinksView(object, links)
                }
            }
        }
    }

    func PageLinksView(_ runner: DBRunner, _ links: [DSKCommon.PageLinkLabel]) -> some View {
        Section {
            ForEach(links, id: \.hashValue) { pageLink in
                NavigationLink {
                    PageLinkView(link: pageLink.link, title: pageLink.title, runnerID: runner.id)
                } label: {
                    HStack {
                        STTThumbView(url: URL(string: pageLink.cover ?? runner.thumbnail))
                            .frame(width: 40, height: 40)
                            .cornerRadius(5)
                        Text(pageLink.title)
                        Spacer()
                    }
                }
            }
        } header: {
            Text(runner.name)
        }
    }
}

extension BrowseView {
    var NoListInstalledView: some View {
        VStack(alignment: .center) {
            Text("New to Suwatte?")
                .font(.headline)
                .fontWeight(.semibold)
            Text("A quick guide on how to make the most of our app.")
                .font(.subheadline)
                .fontWeight(.light)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Button("Get Started") {
                presentOnboarding.toggle()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
    }
}

extension BrowseView {
    struct PendingSetupView: View {
        @EnvironmentObject private var model: PageLinkProviderModel
        var body: some View {
            Section {
                ForEach(model.runnersPendingSetup) { runner in
                    let state = model.pending[runner.id] ?? .setup
                    HStack(spacing: 15) {
                        STTThumbView(url: URL(string: runner.thumbnail))
                            .frame(width: 40, height: 40)
                            .cornerRadius(5)
                        VStack(alignment: .leading) {
                            Text(runner.name)
                            Text(state == .setup ? "\(runner.name) requires additional setup." : "Sign in to \(runner.name) to continue.")
                                .font(.caption.weight(.light).italic())
                        }
                        Spacer()
                        Button(state == .setup ? "Setup" : "Sign In") {
                            if state == .setup {
                                model.selectedRunnerRequiringSetup = runner
                            } else {
                                model.selectedRunnerRequiringAuth = runner
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
    }
}
enum LinkProviderPendingState {
    case authentication, setup
}

struct UpdateRunnersView: View {
    @Binding var data: [DBRunner]

    var body: some View {
        List {
            ForEach(data) { runner in
                HStack(spacing: 15) {
                    STTThumbView(url: URL(string: runner.thumbnail))
                        .frame(width: 40, height: 40)
                        .cornerRadius(5)
                    VStack(alignment: .leading) {
                        Text(runner.name)
                    }
                    Spacer()
                    Button("Update") {
                        update(runner: runner)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .closeButton()
        .navigationTitle("Runner Updates")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: data)
        .toast()
    }

    func update(runner: DBRunner) {
        Task {
            guard let url = URL(string: runner.listURL ?? "") else {
                Logger.shared.error("Could not parse the Runner List", runner.id)
                ToastManager.shared.info("Could not parse the Runner List")
                return
            }
            do {
                try await DSK.shared.importRunner(from: url, with: runner.id)
                await animate {
                    data.removeAll(where: { $0.id == runner.id })
                }
            } catch {
                ToastManager.shared.error(error)
                Logger.shared.error(error, "Update~\(runner.id)")
            }
        }
    }
}
