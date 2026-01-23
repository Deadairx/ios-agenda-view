//
//  GoogleAuthService.swift
//  AgendaView
//

import Foundation
import AuthenticationServices

@MainActor
class GoogleAuthService: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var userEmail: String?
    @Published var isLoading = false
    @Published var error: String?

    private var webAuthSession: ASWebAuthenticationSession?
    private var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?

    private let clientId: String
    private let redirectUri = "com.googleusercontent.apps.683486003424-oj2ocd5o5ifqgp9b3535gpbgv3l53j2k:/oauth2callback"
    private let scopes = ["https://www.googleapis.com/auth/calendar.readonly", "email", "profile"]

    override init() {
        self.clientId = Self.loadClientId()
        super.init()
        checkExistingAuth()
    }

    private static func loadClientId() -> String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let clientId = dict["GOOGLE_CLIENT_ID"] as? String else {
            fatalError("Missing GOOGLE_CLIENT_ID in Secrets.plist")
        }
        return clientId
    }

    private func checkExistingAuth() {
        if let accessToken = KeychainService.get(.accessToken),
           !accessToken.isEmpty,
           let expiryString = KeychainService.get(.tokenExpiry),
           let expiry = Double(expiryString) {
            let expiryDate = Date(timeIntervalSince1970: expiry)
            if expiryDate > Date() {
                isAuthenticated = true
                userEmail = KeychainService.get(.userEmail)
            } else if KeychainService.get(.refreshToken) != nil {
                Task {
                    await refreshToken()
                }
            }
        }
    }

    func signIn(presentationContext: ASWebAuthenticationPresentationContextProviding) async {
        isLoading = true
        error = nil

        let state = UUID().uuidString
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        guard let authUrl = components.url else {
            error = "Failed to create auth URL"
            isLoading = false
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let session = ASWebAuthenticationSession(
                url: authUrl,
                callbackURLScheme: "com.googleusercontent.apps.683486003424-oj2ocd5o5ifqgp9b3535gpbgv3l53j2k"
            ) { [weak self] callbackURL, authError in
                Task { @MainActor in
                    defer { continuation.resume(returning: ()) }

                    guard let self = self else { return }

                    if let authError = authError {
                        if (authError as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                            self.error = authError.localizedDescription
                        }
                        self.isLoading = false
                        return
                    }

                    guard let callbackURL = callbackURL,
                          let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                          let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                        self.error = "Failed to get authorization code"
                        self.isLoading = false
                        return
                    }

                    await self.exchangeCodeForTokens(code: code, codeVerifier: codeVerifier)
                }
            }

            session.presentationContextProvider = presentationContext
            session.prefersEphemeralWebBrowserSession = false
            self.webAuthSession = session
            session.start()
        }
    }

    private func exchangeCodeForTokens(code: String, codeVerifier: String) async {
        let tokenUrl = URL(string: "https://oauth2.googleapis.com/token")!

        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params = [
            "client_id": clientId,
            "code": code,
            "code_verifier": codeVerifier,
            "grant_type": "authorization_code",
            "redirect_uri": redirectUri
        ]

        request.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            saveTokens(tokenResponse)
            await fetchUserInfo()
            isAuthenticated = true
        } catch {
            self.error = "Failed to exchange code: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refreshToken() async {
        guard let refreshToken = KeychainService.get(.refreshToken) else {
            isAuthenticated = false
            return
        }

        let tokenUrl = URL(string: "https://oauth2.googleapis.com/token")!

        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params = [
            "client_id": clientId,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]

        request.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            saveTokens(tokenResponse)
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            KeychainService.deleteAll()
        }
    }

    private func saveTokens(_ response: TokenResponse) {
        _ = KeychainService.save(response.accessToken, for: .accessToken)
        if let refreshToken = response.refreshToken {
            _ = KeychainService.save(refreshToken, for: .refreshToken)
        }
        let expiry = Date().timeIntervalSince1970 + Double(response.expiresIn)
        _ = KeychainService.save(String(expiry), for: .tokenExpiry)
    }

    private func fetchUserInfo() async {
        guard let accessToken = KeychainService.get(.accessToken) else { return }

        let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let userInfo = try JSONDecoder().decode(UserInfo.self, from: data)
            userEmail = userInfo.email
            _ = KeychainService.save(userInfo.email, for: .userEmail)
        } catch {
            print("Failed to fetch user info: \(error)")
        }
    }

    func signOut() {
        KeychainService.deleteAll()
        isAuthenticated = false
        userEmail = nil
    }

    func getValidAccessToken() async -> String? {
        if let expiryString = KeychainService.get(.tokenExpiry),
           let expiry = Double(expiryString) {
            let expiryDate = Date(timeIntervalSince1970: expiry)
            if expiryDate <= Date().addingTimeInterval(60) {
                await refreshToken()
            }
        }
        return KeychainService.get(.accessToken)
    }

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

private struct UserInfo: Codable {
    let email: String
    let name: String?
}
