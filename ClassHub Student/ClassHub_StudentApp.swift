//
//  ClassHub_StudentApp.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 10/25/25.
//

import SwiftUI
import FirebaseCore
import Firebase

@main
struct ClassHub_StudentApp: App {
    // Provide a single AuthViewModel instance for the whole app
    @StateObject private var authViewModel = AuthViewModel()
    init() {
        FirebaseApp.configure()
        #if DEBUG
            let providerFactory = AppCheckDebugProviderFactory()
            AppCheck.setAppCheckProviderFactory(providerFactory)
        #endif
    }
    var body: some Scene {
        WindowGroup {
            SignInView()
                .environmentObject(authViewModel)
        }
    }
}
