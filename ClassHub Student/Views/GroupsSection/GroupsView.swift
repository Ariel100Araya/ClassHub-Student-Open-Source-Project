//
//  GroupsView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 11/1/25.
//

//
//  GradesView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 11/1/25.
//


//
//  ClassesView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 10/30/25.
//


import SwiftUI
import FirebaseDatabase

struct GroupsView: View {
    @ObservedObject private var firebase = FirebaseManager.shared

    // The currently selected group id
    @State private var selectedGroupID: String? = nil

    var body: some View {
        NavigationSplitView {
            // Sidebar: vertical tab-like buttons for each class
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    Text("Groups")
                        .font(.largeTitle)
                        .bold()
                    Button(action: {
                        withAnimation { selectedGroupID = nil }
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
                    ForEach(firebase.groups) { grp in
                        let isSelected = selectedGroupID == grp.id
                        Button(action: {
                            withAnimation { selectedGroupID = grp.id }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "person.3")
                                    .foregroundColor(isSelected ? .white : .accentColor)
                                Text(grp.title ?? "Group")
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
                        //.accessibilityLabel(Text("Select group \(grp.title ?? \"Group\")"))
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Groups")
        } detail: {
            // Detail: put a local NavigationStack here so navigation links in the focused view
            // push inside the detail column only.
            NavigationStack {
                if let gid = selectedGroupID {
                    let title = firebase.groups.first(where: { $0.id == gid })?.title ?? "Group"
                    FocusedGroupView(groupName: title, groupID: gid)
                 } else {
                     // placeholder when nothing is selected
                     GroupsSummaryView()
                 }
             }
         }
     }
 }
