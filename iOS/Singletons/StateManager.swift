//
//  StateManager.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2023-05-12.
//

import Combine
import Foundation
import Network
import Nuke
import UIKit
import RealmSwift

final class StateManager: ObservableObject {
    static let shared = StateManager()
    var networkState = NetworkState.unknown
    let monitor = NWPathMonitor()
    let runnerListPublisher = PassthroughSubject<Void, Never>()
    @Published var readerState: ReaderState?

    init() {
        registerNetworkObserver()
        updateAnilistNSFWSetting()
    }

    func didStateChange() {
        updateAnilistNSFWSetting()
    }

    func registerNetworkObserver() {
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                self?.networkState = .online
            } else {
                self?.networkState = .offline
            }
        }
    }

    func updateAnilistNSFWSetting() {
        guard NetworkStateHigh else {
            return
        }
    }

    var NetworkStateHigh: Bool {
        networkState == .online || networkState == .unknown
    }

    func clearMemoryCache() {
        ImagePipeline.shared.configuration.imageCache?.removeAll()
    }
    
    func alert(title: String, message: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        controller.addAction(action)
        KEY_WINDOW?.rootViewController?.present(controller, animated: true)
    }
}

extension StateManager {
    enum NetworkState {
        case unknown, online, offline
    }
}


// MARK: - Global Chapter Reading
extension StateManager {
    
    struct ReaderState : Identifiable {
        var id: String { chapter.id }
        let chapter: StoredChapter
        let chapters: [StoredChapter]
        let requestedPage: Int?
        let readingMode: ReadingMode?
    }
    
    func openReader(context: DSKCommon.ReaderContext, caller: DSKCommon.Highlight, source: String) {
        
        // Ensure the chapter to be opened is in the provided chapter list
        let targetInList = context.chapters.map(\.chapterId).contains(context.target)
        guard targetInList else {
            alert(title: "Error", message: "Tried opening to a chapter not provided in the chapter list")
            return
        }
        
        
        // Save Content, if not saved
        let highlight = context.content ?? caller
        let streamable = highlight.canStream
        let target = DataManager.shared.getStoredContent(ContentIdentifier(contentId: highlight.contentId, sourceId: source).id)
        
        // Target Title is already in the db, Just update the streamble flag
        if let target, target.streamable != streamable {
            let realm = try! Realm()
            try! realm.safeWrite {
                target.streamable = streamable
            }
        } else {
            // target title not saved to db, save
            let content = highlight.toStored(sourceId: source)
            DataManager.shared.storeContent(content)
        }
        
        // Add Chapters to DB
        let chapters = context.chapters.map { $0.toStoredChapter(withSource: source )}
        
    
        // Open Reader
        let chapter = chapters.first(where: { $0.chapterId == context.target })!
        self.readerState = .init(chapter: chapter, chapters: chapters, requestedPage: context.requestedPage, readingMode: context.readingMode)
    }
    
    func stream(item: DSKCommon.Highlight, sourceId: String) {
        ToastManager.shared.loading = true
        Task {
            do {
                let source = try DSK.shared.getContentSource(id: sourceId)
                let context = try await source.provideReaderContext(for: item.contentId)
                Task { @MainActor in
                    ToastManager.shared.loading = false
                    StateManager.shared.openReader(context: context, caller: item, source: sourceId)
                }
            } catch {
                Task { @MainActor in
                    ToastManager.shared.loading = false
                    StateManager.shared.alert(title: "Error",
                                              message: "\(error.localizedDescription)")
                }
                Logger.shared.error(error, sourceId)
            }
        }
    }
}
