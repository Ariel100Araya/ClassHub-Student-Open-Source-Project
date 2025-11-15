//
//  AuthViewModel.swift
//  host
//
//  Originally Created by Ariel Araya-Madrigal on 8/21/25.
//  Added to ClassHub by Ariel Araya-Madrigal on 11/3/25.
//


import SwiftUI
import FirebaseAuth
import Combine

class AuthViewModel: ObservableObject {
    @Published var user: User? = nil
    @Published var isSignedIn: Bool = false

    init() {
        self.user = Auth.auth().currentUser
        self.isSignedIn = user != nil
    }

    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Sign Up Error: \(error.localizedDescription)")
                return
            }
            self.user = result?.user
            self.isSignedIn = true
        }
    }

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Sign In Error: \(error.localizedDescription)")
                return
            }
            self.user = result?.user
            self.isSignedIn = true
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isSignedIn = false
        } catch {
            print("Sign Out Error: \(error.localizedDescription)")
        }
    }
}
