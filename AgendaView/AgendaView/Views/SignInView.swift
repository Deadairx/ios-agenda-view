//
//  SignInView.swift
//  AgendaView
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @ObservedObject var authService: GoogleAuthService

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                Text("Agenda Widget")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Sign in with Google to sync your calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            if authService.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                GoogleSignInButton(authService: authService)
            }

            if let error = authService.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }
}

struct GoogleSignInButton: View {
    @ObservedObject var authService: GoogleAuthService
    @State private var presentationAnchor = AuthPresentationAnchor()

    var body: some View {
        Button {
            Task {
                await authService.signIn(presentationContext: presentationAnchor)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .font(.title2)
                Text("Sign in with Google")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

class AuthPresentationAnchor: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
