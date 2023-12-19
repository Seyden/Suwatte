//
//  +CollectionFilter.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2023-08-01.
//

import Foundation
import RealmSwift

struct CollectionFilter: Codable {
    var adultContent: ContentSelectionType = .both
    var readingFlags: [LibraryFlag] = []
    var textContains: [String] = []
    var statuses: [ContentStatus] = []
    var sources : [String] = []
    var tagContains: [String] = []
    var contentType : [ExternalContentType] = []
}


enum ContentSelectionType: Int, PersistableEnum, CaseIterable, Identifiable, Codable {
    case none, only, both

    var description: String {
        switch self {
        case .none:
            return "None"
        case .only:
            return "Only"
        case .both:
            return "Both"
        }
    }

    var id: Int {
        hashValue
    }
}

enum ExternalContentType: Int, PersistableEnum, CaseIterable, Identifiable, Codable {
    case manga, manhua, manhwa, comic, novel

    var id: Int {
        hashValue
    }

    var description: String {
        switch self {
        case .novel:
            return "Novel"
        case .manga:
            return "Manga"
        case .manhua:
            return "Manhua"
        case .manhwa:
            return "Manhwa"
        case .comic:
            return "Comic"
        }
    }
}
