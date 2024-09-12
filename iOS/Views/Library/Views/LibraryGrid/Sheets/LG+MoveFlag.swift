//
//  LG+MoveFlag.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2022-09-27.
//

import RealmSwift
import SwiftUI

enum SelectionState {
    case none, some, all
}

extension LibraryView.LibraryGrid {
    struct MoveReadingFlag: View {
        var entries: [LibraryEntry]
        @Environment(\.presentationMode) var presentationMode
        @EnvironmentObject var model: ViewModel

        var body: some View {
            SmartNavigationView {
                List {
                    Section {
                        ForEach(LibraryFlag.allCases) { flag in
                            let state = state(for: flag)
                            Button { setFlags(flag) } label: {
                                HStack {
                                    Text(flag.description)
                                    Spacer()
                                    ZStack {
                                        switch state {
                                        case .none:
                                            EmptyView()
                                        case .some:
                                            Text("-")
                                        case .all:
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .font(.body.weight(.light))
                                    .foregroundColor(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                    } header: {
                        Text("Flags")
                    }
                }
                .closeButton()
                .navigationTitle("Change Reading Flag")
                .buttonStyle(.plain)
            }
        }

        func setFlags(_ flag: LibraryFlag) {
            model.clearSelection()
            let targets = entries
                .map { $0.id }
            let ids = Set(targets)
            Task {
                let actor = await Suwatte.RealmActor.shared()
                await actor.bulkSetReadingFlag(for: ids, to: flag)
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

extension LibraryView.LibraryGrid.MoveReadingFlag {
    func state(for flag: LibraryFlag) -> SelectionState {
        if entries.allSatisfy({ $0.flag == flag }) {
            return .all
        } else if entries.contains(where: { $0.flag == flag }) {
            return .some
        } else {
            return .none
        }
    }

    func selectionBadge(for state: SelectionState) -> String {
        switch state {
        case .none:
            return ""
        case .some:
            return "-"
        case .all:
            return "\(Image(systemName: "checkmark"))"
        }
    }
}
