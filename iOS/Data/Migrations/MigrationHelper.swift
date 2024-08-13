//
//  Migration.swift
//  Suwatte (iOS)
//
//  Created by Seyden on 02.05.24.
//

import Foundation
import RealmSwift

class MigrationHelper {
    static func migrateContentLinks(migration: Migration) {
        migration.enumerateObjects(ofType: ContentLink.className()) { oldContentLinkObject, newContentLinkObject in
            guard let oldContentLinkObject = oldContentLinkObject else { return }

            let isDeleted = oldContentLinkObject["isDeleted"] as! Bool
            if isDeleted { return }

            var ids = Set(oldContentLinkObject["ids"] as! RealmSwift.MutableSet<String>)

            migration.enumerateObjects(ofType: LibraryEntry.className()) { _, libraryEntryObject in
                guard let libraryEntryObject else { return }
                if let libraryEntryId = libraryEntryObject["id"] as? String {

                    if ids.remove(libraryEntryId) != nil {

                        ids.forEach { linkContentId in
                            let newLink = migration.create(ContentLink.className())
                            newLink["id"] = "\(libraryEntryId)||\(linkContentId)"
                            newLink["entry"] = libraryEntryObject

                            migration.enumerateObjects(ofType: StoredContent.className()) { _, contentObject in
                                guard let contentObject else { return }
                                if let contentId = contentObject["id"] as? String {
                                    if contentId == linkContentId {
                                        newLink["content"] = contentObject
                                    }
                                }
                            }
                        }

                        migration.delete(newContentLinkObject!)
                    }
                }
            }
        }
    }
  
    static func migrateProgressMarker(migration: Migration) {
        migration.renameProperty(onType: ProgressMarker.className(), from: "currentChapter", to: "chapter")
        migration.enumerateObjects(ofType: ProgressMarker.className()) { oldProgressMarkerObject, newProgressMarkerObject in
            guard let oldProgressMarkerObject = oldProgressMarkerObject else { return }

            let isDeleted = oldProgressMarkerObject["isDeleted"] as! Bool
            if isDeleted { return }

            let contentId = oldProgressMarkerObject["id"] as! String

            let dateRead = oldProgressMarkerObject["dateRead"] as? Date

            let readChapters = Set(oldProgressMarkerObject["readChapters"] as! RealmSwift.MutableSet<Double>)

            var migrated = false
            for readChapter in readChapters {
                migration.enumerateObjects(ofType: StoredChapter.className()) { _, storedChapter in

                    guard let storedChapter else { return }

                    let chapterId = storedChapter["id"] as! String
                    let chapterContentId = storedChapter["contentId"] as! String
                    let chapterSourceId = storedChapter["sourceId"] as! String
                    let chapterConcatedId = "\(chapterSourceId)||\(chapterContentId)"
                    let chapterChapterId = storedChapter["chapterId"] as! String
                    let chapterNumber = storedChapter["number"] as! Double
                    let chapterVolume = storedChapter["volume"] as? Double

                    if chapterConcatedId == contentId {
                        let chapterOrderKey = ThreadSafeChapter.orderKey(volume: readChapter < 10000 ? 0 : storedChapter["volume"] as? Double, number: storedChapter["number"] as! Double)

                        if chapterOrderKey == readChapter {
                            let newProgressMarker = migration.create(ProgressMarker.className())

                            var foundReference = false

                            migration.enumerateObjects(ofType: ChapterReference.className()) { _, chapterRef in
                                guard let chapterRef else { return }

                                if chapterRef["id"] as! String == chapterId {
                                    newProgressMarker["chapter"] = chapterRef
                                    foundReference = true
                                    return
                                }
                            }
                            
                            if !foundReference {

                                var newChapterContent: MigrationObject?

                                migration.enumerateObjects(ofType: StoredContent.className()) { _, storedContent in
                                    guard let storedContent, contentId == storedContent["id"] as! String else { return }

                                    newChapterContent = storedContent
                                    return
                                }
                                let chapterReference = migration.create(ChapterReference.className())
                                chapterReference["id"] = chapterId
                                chapterReference["chapterId"] = chapterChapterId
                                chapterReference["number"] = chapterNumber
                                chapterReference["volume"] = chapterVolume == 0.0 ? nil : chapterVolume
                                chapterReference["content"] = newChapterContent
                                newProgressMarker["chapter"] = chapterReference
                            }

                            newProgressMarker["id"] = chapterId
                            newProgressMarker["totalPageCount"] = 1
                            newProgressMarker["lastPageRead"] = 1
                            newProgressMarker["lastPageOffsetPCT"] = nil
                            newProgressMarker["dateRead"] = dateRead

                            migrated = true
                            return
                        }
                    }
                }
            }

            if migrated {

                migration.delete(newProgressMarkerObject!)
            }
        }
    }

    static let interactorStoreObjectTypeName: String = "InteractorStoreObject"

    static func migrateInteractorStoreObjects(migration: Migration) {
        let userDefaultKey = "InteractorStoreObjects"
        var interactorStoreObjects = UserDefaults.standard.dictionary(forKey: userDefaultKey) as? [String: String] ?? [:]
        let countBeforeMigration = interactorStoreObjects.count

        migration.enumerateObjects(ofType: interactorStoreObjectTypeName) { oldInteractorStoreObject, _ in
            guard let oldInteractorStoreObject = oldInteractorStoreObject else { return }

            let id = oldInteractorStoreObject["id"] as! String
            let value = oldInteractorStoreObject["value"] as! String

            interactorStoreObjects[id] = value
        }

        if interactorStoreObjects.count > countBeforeMigration {
            UserDefaults.standard.set(interactorStoreObjects, forKey: userDefaultKey)
            migration.deleteData(forType: "InteractorStoreObject")
        }
    }

    static func migrationCheck(realm: Realm) {
        let schema = realm.schema[interactorStoreObjectTypeName]
        if schema != nil {
            let interactorStoreObjects = realm.dynamicObjects(interactorStoreObjectTypeName)
            assert(interactorStoreObjects.count == 0, "InteractorStoreObject wasn't fully migrated and there are still objects left inside.")
        }
    }
}
