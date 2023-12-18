//
//  Runner.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2022-08-07.
//

import Foundation
import IceCream
import RealmSwift

enum RunnerEnvironment: String, PersistableEnum, Codable, Hashable {
    case unknown, tracker, source

    var description: String {
        switch self {
        case .tracker:
            return "Trackers"
        case .source:
            return "Sources"
        case .unknown:
            return "Unknown"
        }
    }
}

struct RunnerList: Codable, Hashable {
    var listName: String?
    var runners: [Runner]
}

struct Runner: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var version: Double
    var website: String?
    var supportedLanguages: [String]?
    var path: String
    let rating: CatalogRating?
    var environment: RunnerEnvironment = .unknown
    var thumbnail: String?
    var minSupportedAppVersion: String?
}
