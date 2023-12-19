//
//  ManageCollectionsView.swift
//  Suwatte
//
//  Created by Mantton on 2022-03-08.
//

import SwiftUI

extension LibraryView {
    struct ManageCollectionsView: View {
        @Environment(\.presentationMode) private var presentationMode
        @EnvironmentObject private var model: StateManager
        @FetchRequest(fetchRequest: CDCollection.fetchAll(), animation: .default)
        private var records: FetchedResults<CDCollection>
        

        var body: some View {
            SmartNavigationView {
                List {
                    AdditionSection
                    EditorSection
                }
                .navigationTitle("Collections")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    EditButton()
                })
                .closeButton()
            }
        }
    }
}

private typealias MCV = LibraryView.ManageCollectionsView
extension MCV {
    var AdditionSection: some View {
        AddCollectionView()
    }
}

extension MCV {
    var EditorSection: some View {
        Section {
            ForEach(records) { collection in
                NavigationLink {
                    EmptyView()
                    CollectionManagementView(collection: collection, collectionName: collection.name)
                } label: {
                    Text(collection.name)
                }
            }
            .onDelete(perform: delete)
            .onMove(perform: move)
        } header: {
            Text("Collections")
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        var arr = records.map(\.collectionID) as [String]
        arr.move(fromOffsets: source, toOffset: destination)

        CDCollection.reorder(arr)
    }

    func delete(from idxs: IndexSet) {
        let ids = idxs.compactMap { records.getOrNil($0)?.collectionID }
        ids.forEach { id in
            CDCollection.remove(id)
        }
    }
}

extension MCV {
    struct AddCollectionView: View {
        @State var name: String = ""

        var body: some View {
            Section {
                TextField("Collection Name", text: $name)
                    .onSubmit {
                        addCollection()
                    }
                HStack {
                    Spacer()
                    Button("Add Collection") { addCollection() }
                        .buttonStyle(.bordered)
                    Spacer()
                }

            } header: {
                Text("New Collection")
            }
        }

        func addCollection() {
            if name.isEmpty {
                return
            }
            let val = name
            name = ""
            CDCollection.add(name: val)
        }
    }
}

// MARK: Edit View

extension MCV {
    struct CollectionEditView: View {
        @State private var name: String
        let collection: CDCollection
        @State  private var showDone = false
        @Binding private var editting: Bool
        var body: some View {
            HStack {
                TextField("Enter Name", text: $name, onEditingChanged: { change in

                    if change {
                        withAnimation {
                            editting = false
                            showDone = true
                        }
                    } else {
                        withAnimation {
                            showDone = false
                        }
                    }

                })
                if showDone {
                    Button("Done") {
                        if !name.isEmpty {
                            CDCollection.rename(collection, name: name)
                        }
                        resign()
                    }
                }
            }
        }

        @MainActor
        private func resign() {
            withAnimation {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                showDone = false
                editting = true
            }
        }
    }
}
