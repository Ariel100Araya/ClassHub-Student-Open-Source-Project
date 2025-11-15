//
//  ClassesView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 10/29/25.
//

import SwiftUI
import FirebaseDatabase

struct ClassesView: View {
    // Observe Firebase-backed classes
    @ObservedObject private var firebase = FirebaseManager.shared

    // The currently selected class id (binds to the sidebar selection)
    @State private var selectedClassID: String? = nil

    var body: some View {
        NavigationSplitView {
            // Sidebar: vertical tab-like buttons for each class
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    Text("Classes")
                        .font(.largeTitle)
                        .bold()
                    Button(action: {
                        withAnimation { selectedClassID = nil }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar.badge.clock")
                            Text("Summary")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                    ForEach(firebase.classes) { cls in
                        let isSelected = selectedClassID == cls.id
                        Button(action: {
                            withAnimation { selectedClassID = cls.id }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "book.closed")
                                    .foregroundColor(isSelected ? .white : .accentColor)
                                Text(cls.name)
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? Color.accentColor : Color.clear)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel(Text("Select class \(cls.name)"))
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Classes")
        } detail: {
            // Detail: put a local NavigationStack here so navigation links in the focused view
            // push inside the detail column only.
            NavigationStack {
                if let classID = selectedClassID {
                    let name = firebase.className(for: classID)
                    FocusedClassView(className: name, classID: classID)
                } else {
                    // placeholder when nothing is selected
                    ClassSummaryView()
                }
            }
        }
    }
}

#Preview {
    ClassesView()
}
