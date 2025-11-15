//
//  SignInView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 11/3/25.
//

import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @StateObject private var viewModel = AuthViewModel()

    @State private var email = ""
    @State private var password = ""
    var body: some View {
        if viewModel.isSignedIn {
            ContentView()
        } else {
            VStack {
                Text("Hi there!")
                    .font(.largeTitle)
                    .padding()
                    .multilineTextAlignment(.center)
                Text("Let's sign in.")
                    .font(.title2)
                    .padding()
                    .multilineTextAlignment(.center)
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                HStack {
                    Button("Sign In") {
                        viewModel.signIn(email: email, password: password)
                    }
                    Button("Sign Up") {
                        viewModel.signUp(email: email, password: password)
                    }
                }
            }
        }
    }
}

#Preview {
    SignInView()
}
