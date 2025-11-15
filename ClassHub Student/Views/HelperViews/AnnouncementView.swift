//
//  AnnouncementView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 11/4/25.
//

import SwiftUI

struct AnnouncementView: View {
    @State var announementTitle: String
    @State var announementSubtitle: String
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Header with title and submit
                HStack {
                    VStack(alignment: .leading, spacing: 12) {
                        if !announementTitle.isEmpty {
                            Text(announementTitle)
                                .font(.largeTitle)
                                .bold()
                                .padding()
                            Text(announementSubtitle)
                                .font(.title2)
                                .padding()
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
        }
    }
}
