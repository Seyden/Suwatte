//
//  CollectionManagementView.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2022-07-31.
//

import RealmSwift
import SwiftUI

struct CollectionManagementView: View {
    let collection: CDCollection
    @State var collectionName: String
    @State var enableFilters: Bool = false

    var body: some View {
        List {
            HStack {
                Text("Name: ")
                    .fontWeight(.light)
                    .foregroundColor(.gray)
                TextField("Collection Name", text: $collectionName)
            }

            Toggle("Enable Smart Filters", isOn: $enableFilters)

            if let filter = collection.filter, enableFilters {
                FilterSections(collection: collection,
                               adultContent: filter.adultContent,
                               sourceSelections: filter.sources,
                               flagSelections: filter.readingFlags,
                               contentSelections: filter.contentType,
                               titleContains: filter.textContains,
                               tagContains: filter.tagContains,
                               contentStatuses: filter.statuses)
                    .transition(.slide)
                    .animation(.default)
            }
        }
        .onAppear(perform: load)
        .onSubmit {
            saveName(collectionName)
        }

        .onChange(of: enableFilters, perform: handleToggleFilterEnabled)
        .animation(.default)
        .navigationTitle("Manage \(collection.name)")
        .navigationBarTitleDisplayMode(.inline)
    }

    func saveName(_ str: String) {
        if str.isEmpty {
            collectionName = collection.name
            return
        }
        let id = collection.collectionID
        CDCollection.rename(id, name: str)
    }

    func load() {
        collectionName = collection.name
        enableFilters = collection.filter != nil
    }
}

extension CollectionManagementView {
    struct FilterSections: View {
        let collection: CDCollection
        @State var adultContent = ContentSelectionType.both
        @State var sourceSelections: [String]
        @State var flagSelections: [LibraryFlag]
        @State var contentSelections: [ExternalContentType]
        @State var titleContains: [String]
        @State var tagContains: [String]
        @State var contentStatuses: [ContentStatus]
        @State var titleText = ""
        @State var tagText = ""
        @State var sources: [DBRunner] = []
        var body: some View {
            AdultContentSection
            TitlesSection
            Section {
                // MARK: Content Status

                ContentStatusSection

                // MARK: Reading Flag

                ReadingFlagSection

                // MARK: Content Type

                ContentTypeSection
            }
            SourcesSection

                .onChange(of: adultContent) { _ in
                    saveAll()
                }
                .onChange(of: sourceSelections) { _ in
                    saveAll()
                }
                .onChange(of: flagSelections) { _ in
                    saveAll()
                }
                .onChange(of: contentSelections) { _ in
                    saveAll()
                }

                .onChange(of: tagContains) { _ in
                    saveAll()
                }
                .onChange(of: titleContains) { _ in
                    saveAll()
                }
                .onChange(of: contentStatuses) { _ in
                    saveAll()
                }
                .task {
                    let actor = await RealmActor.shared()
                    sources = CDRunner.getAll()
                }
        }
    }
}

extension CollectionManagementView.FilterSections {
    var AdultContentSection: some View {
        Section {
            NavigationLink {
                List {
                    ForEach(ContentSelectionType.allCases) { selection in
                        Button {
                            adultContent = selection
                        } label: {
                            HStack {
                                Text(selection.description)
                                Spacer()
                                if adultContent == selection {
                                    Image(systemName: "checkmark")
                                        .transition(.scale)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(NeutralButtonStyle())
                    }
                }
                .animation(.default, value: adultContent)

                .navigationBarTitle("Adult Content")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                Text("Adult Content")
            }
        }
    }

    var TitlesSection: some View {
        Section {
            NavigationLink {
                List {
                    Section {
                        TextField("String", text: $titleText)
                        Button("Add") {
                            titleContains.append(titleText)
                            titleText.removeAll()
                        }.disabled(titleText.isEmpty)
                    }

                    Section {
                        ForEach(titleContains) { query in
                            Text(query)
                        }
                        .onDelete(perform: removeTitles(at:))
                    }
                }
                .animation(.default, value: titleContains)
                .navigationTitle("Title or Sumamry Contains")

            } label: {
                Text("Title or Summary Contains")
            }
            NavigationLink {
                List {
                    Section {
                        TextField("String", text: $tagText)
                        Button("Add") {
                            tagContains.append(tagText)
                            tagText.removeAll()
                        }.disabled(tagText.isEmpty)
                    }

                    Section {
                        ForEach(tagContains) { tag in
                            Text(tag)
                        }
                        .onDelete(perform: removeTags(at:))
                    }
                }

                .animation(.default, value: tagContains)

                .navigationTitle("Tags")

            } label: {
                Text("Tag Contains")
            }
        }
    }

    var ContentStatusSection: some View {
        NavigationLink {
            List {
                ForEach(ContentStatus.allCases, id: \.hashValue) { c in
                    Button {
                        if contentStatuses.contains(c) { contentStatuses.removeAll(where: { $0 == c }) } else {
                            contentStatuses.append(c)
                        }
                    } label: {
                        HStack {
                            Text(c.description)
                            Spacer()
                            if contentStatuses.contains(c) {
                                Image(systemName: "checkmark")
                                    .transition(.scale)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(NeutralButtonStyle())
                }
            }
            .animation(.default, value: contentStatuses)
            .navigationBarTitle("Content Status")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            Text("Content Status")
        }
    }

    var ReadingFlagSection: some View {
        NavigationLink {
            List {
                ForEach(LibraryFlag.allCases) { flag in
                    Button {
                        if flagSelections.contains(flag) { flagSelections.removeAll(where: { $0 == flag }) } else {
                            flagSelections.append(flag)
                        }
                    } label: {
                        HStack {
                            Text(flag.description)
                            Spacer()
                            if flagSelections.contains(flag) {
                                Image(systemName: "checkmark")
                                    .transition(.scale)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(NeutralButtonStyle())
                }
            }
            .animation(.default, value: flagSelections)

            .navigationBarTitle("Reading Flags")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            Text("Reading Flags")
        }
    }

    var ContentTypeSection: some View {
        NavigationLink {
            List {
                ForEach(ExternalContentType.allCases) { c in
                    Button {
                        if contentSelections.contains(c) { contentSelections.removeAll(where: { $0 == c }) } else {
                            contentSelections.append(c)
                        }
                    } label: {
                        HStack {
                            Text(c.description)
                            Spacer()
                            if contentSelections.contains(c) {
                                Image(systemName: "checkmark")
                                    .transition(.scale)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(NeutralButtonStyle())
                }
            }
            .animation(.default, value: contentSelections)
            .navigationBarTitle("Content Type")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            Text("Content Type")
        }
    }

    var SourcesSection: some View {
        Section {
            NavigationLink {
                List {
                    ForEach(Array(sources), id: \.id) { source in
                        Button {
                            if sourceSelections.contains(source.id) { sourceSelections.removeAll(where: { $0 == source.id }) } else {
                                sourceSelections.append(source.id)
                            }
                        } label: {
                            HStack {
                                Text(source.name)
                                Spacer()
                                if sourceSelections.contains(source.id) {
                                    Image(systemName: "checkmark")
                                        .transition(.scale)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(NeutralButtonStyle())
                    }
                }
                .animation(.default, value: sourceSelections)
                .navigationBarTitle("Sources")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                Text("Sources")
            }
        }
    }
}

extension CollectionManagementView.FilterSections {
    func removeTags(at offsets: IndexSet) {
        tagContains.remove(atOffsets: offsets)
    }

    func removeTitles(at offsets: IndexSet) {
        titleContains.remove(atOffsets: offsets)
    }

    func saveAll() {
        var filter = CollectionFilter()

        filter.adultContent = adultContent
        filter.sources.append(contentsOf: sourceSelections)
        filter.readingFlags.append(contentsOf: flagSelections)
        filter.contentType.append(contentsOf: contentSelections)
        filter.tagContains.append(contentsOf: tagContains)
        filter.textContains.append(contentsOf: titleContains)
        filter.statuses.append(contentsOf: contentStatuses)
        
        CDCollection.addFilter(collection, filter: filter)
    }
}

extension CollectionManagementView {
    func handleToggleFilterEnabled(_ value: Bool) {
        if collection.filter_ == nil {
            CDCollection.addFilter(collection, filter: .init())
        } else {
            CDCollection.removeFilter(collection)
        }
    }
}
