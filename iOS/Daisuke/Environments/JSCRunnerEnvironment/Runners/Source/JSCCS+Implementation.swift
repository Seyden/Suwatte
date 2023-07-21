//
//  JSCCS+Implementation.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2023-07-06.
//

import Foundation


extension JSCContentSource  {
    func getContent(id: String) async throws -> DSKCommon.Content {
        try await callMethodReturningObject(method: "getContent", arguments: [id], resolvesTo: DSKCommon.Content.self)
    }
    
    func getContentChapters(contentId: String) async throws -> [DSKCommon.Chapter] {
        try await callMethodReturningDecodable(method: "getChapters", arguments: [contentId], resolvesTo: [DSKCommon.Chapter].self)
    }
    
    func getChapterData(contentId: String, chapterId: String) async throws -> DSKCommon.ChapterData {
        try await callMethodReturningObject(method: "getChapterData", arguments: [contentId, chapterId], resolvesTo: DaisukeEngine.Structs.ChapterData.self)
    }

    
    func getAllTags() async throws -> [DaisukeEngine.Structs.Property] {
        if let directoryTags {
            return directoryTags
        }
        let data: [DaisukeEngine.Structs.Property] = try await callMethodReturningDecodable(method: "getTags", arguments: [], resolvesTo: [DSKCommon.Property].self)
        self.directoryTags = data
        return data
    }

    
    func getReadChapterMarkers(contentId: String) async throws -> [String] {
        return try await callMethodReturningDecodable(method: "getReadChapterMarkers", arguments: [contentId], resolvesTo: [String].self)
    }
    
    func syncUserLibrary(library: [DSKCommon.UpSyncedContent]) async throws -> [DSKCommon.DownSyncedContent] {
        let data = try DaisukeEngine.encode(value: library)
        let library = try JSONSerialization.jsonObject(with: data)
        return try await callMethodReturningDecodable(method: "syncUserLibrary", arguments: [library], resolvesTo: [DSKCommon.DownSyncedContent].self)
    }
    
    func getIdentifiers(for id: String) async throws -> DaisukeEngine.Structs.URLContentIdentifer? {
        return try await callMethodReturningDecodable(method: "getIdentifierForURL", arguments: [id], resolvesTo: DSKCommon.URLContentIdentifer?.self)
    }
}
// MARK:-  Library Event handler
extension JSCCS {
    func onContentsAddedToLibrary(ids: [String]) async throws {
        try await callOptionalVoidMethod(method: "onContentsAddedToLibrary", arguments: [ids])
    }
    
    func onContentsRemovedFromLibrary(ids: [String]) async throws {
        try await callOptionalVoidMethod(method: "onContentsRemovedFromLibrary", arguments: [ids])
    }
    
    func onContentsReadingFlagChanged(ids: [String], flag: LibraryFlag) async throws {
        try await callOptionalVoidMethod(method: "onContentsReadingFlagChanged", arguments: [ids, flag.rawValue])
    }
}

// MARK: - Chapter Event Handler
extension JSCCS {
    func onChaptersMarked(contentId: String, chapterIds: [String], completed: Bool) async throws {
        try await callOptionalVoidMethod(method: "onChaptersMarked", arguments: [contentId, chapterIds, completed])
    }
    
    func onChapterRead(contentId: String, chapterId: String) async throws {
        try await callOptionalVoidMethod(method: "onChapterRead", arguments: [contentId, chapterId])
    }
    
    func onPageRead(contentId: String, chapterId: String, page: Int) async throws {
        try await callOptionalVoidMethod(method: "onPageRead",
                                         arguments: [contentId, chapterId, page])
    }
}

// MARK: - MediaServerBridge
extension JSCContentSource {

    
    func provideReaderContext(for contentId: String) async throws -> DSKCommon.ReaderContext {
        return try await callMethodReturningObject(method: "provideReaderContext",
                                                   arguments: [contentId],
                                                   resolvesTo: DSKCommon.ReaderContext.self)
    }
}


// MARK: - Context Handler
extension JSCContentSource {
    func getHighlight(highlight: DSKCommon.Highlight) async throws -> DSKCommon.Highlight {
        try await callMethodReturningDecodable(method: "getHighlight",
                                               arguments: [try highlight.asDictionary()],
                                               resolvesTo: DSKCommon.Highlight.self)
    }
    
    func getContextActions(highlight: DSKCommon.Highlight) throws -> [[DSKCommon.ContextMenuAction]] {
        return try synchronousCall(method: "getContextActions", arguments: [try highlight.asDictionary()])
    }
    
    func didTriggerContextActon(highlight: DSKCommon.Highlight, key: String) async throws {
        let object = try highlight.asDictionary()
        return try await callOptionalVoidMethod(method: "didTriggerContextAction",
                                                arguments: [object, key])
    }
}
