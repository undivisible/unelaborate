import Foundation

struct MicrosoftDeviceCodeResponse: Codable {
    let deviceCode: String
    let userCode: String
    let verificationURI: String
    let expiresIn: Int
    let interval: Int
    let message: String

    enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationURI = "verification_uri"
        case expiresIn = "expires_in"
        case interval
        case message
    }
}

struct MicrosoftTokenResponse: Codable {
    let tokenType: String
    let scope: String
    let expiresIn: Int
    let accessToken: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case tokenType = "token_type"
        case scope
        case expiresIn = "expires_in"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

private struct OAuthErrorResponse: Codable {
    let error: String
}

private struct XboxAuthRequest: Codable {
    let properties: XboxAuthProperties
    let relyingParty: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case properties = "Properties"
        case relyingParty = "RelyingParty"
        case tokenType = "TokenType"
    }
}

private struct XboxAuthProperties: Codable {
    let authMethod: String
    let siteName: String
    let rpsTicket: String

    enum CodingKeys: String, CodingKey {
        case authMethod = "AuthMethod"
        case siteName = "SiteName"
        case rpsTicket = "RpsTicket"
    }
}

private struct XboxAuthResponse: Codable {
    let token: String
    let displayClaims: XboxDisplayClaims

    enum CodingKeys: String, CodingKey {
        case token = "Token"
        case displayClaims = "DisplayClaims"
    }
}

private struct XboxDisplayClaims: Codable {
    let xui: [XboxUserClaim]
}

private struct XboxUserClaim: Codable {
    let uhs: String
}

private struct XSTSAuthRequest: Codable {
    let properties: XSTSProperties
    let relyingParty: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case properties = "Properties"
        case relyingParty = "RelyingParty"
        case tokenType = "TokenType"
    }
}

private struct XSTSProperties: Codable {
    let sandboxID: String
    let userTokens: [String]

    enum CodingKeys: String, CodingKey {
        case sandboxID = "SandboxId"
        case userTokens = "UserTokens"
    }
}

private struct XSTSAuthResponse: Codable {
    let token: String
    let displayClaims: XboxDisplayClaims

    enum CodingKeys: String, CodingKey {
        case token = "Token"
        case displayClaims = "DisplayClaims"
    }
}

private struct MinecraftLoginRequest: Codable {
    let identityToken: String
}

private struct MinecraftLoginResponse: Codable {
    let accessToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}

private struct MinecraftProfileResponse: Codable {
    let id: String
    let name: String
}

struct LauncherAccount: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date
    let username: String
    let uuid: String
}

enum MicrosoftAuthError: Error {
    case authorizationPending
    case slowDown
    case authenticationFailed
    case missingXboxClaim
}

actor MicrosoftAuthService {
    private let clientID = "00000000402B5328"
    private let deviceCodeURL = URL(string: "https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode")!
    private let tokenURL = URL(string: "https://login.microsoftonline.com/consumers/oauth2/v2.0/token")!
    private let scope = "XboxLive.signin offline_access"

    func beginDeviceCode() async throws -> MicrosoftDeviceCodeResponse {
        var req = URLRequest(url: deviceCodeURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = "client_id=\(clientID)&scope=\(scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? scope)".data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(MicrosoftDeviceCodeResponse.self, from: data)
    }

    func pollForToken(deviceCode: String, interval: Int) async throws -> MicrosoftTokenResponse {
        while true {
            try await Task.sleep(for: .seconds(interval))

            var req = URLRequest(url: tokenURL)
            req.httpMethod = "POST"
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let body = "grant_type=urn:ietf:params:oauth:grant-type:device_code&client_id=\(clientID)&device_code=\(deviceCode)"
            req.httpBody = body.data(using: .utf8)

            let (data, _) = try await URLSession.shared.data(for: req)
            if let token = try? JSONDecoder().decode(MicrosoftTokenResponse.self, from: data) {
                return token
            }

            if let oauthError = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data) {
                if oauthError.error == "authorization_pending" { continue }
                if oauthError.error == "slow_down" { continue }
                throw MicrosoftAuthError.authenticationFailed
            }
        }
    }

    func authenticateMinecraft(msToken: MicrosoftTokenResponse) async throws -> LauncherAccount {
        let xbox = try await authenticateXboxLive(msAccessToken: msToken.accessToken)
        let xsts = try await authenticateXSTS(xblToken: xbox.token)
        guard let uhs = xsts.displayClaims.xui.first?.uhs else {
            throw MicrosoftAuthError.missingXboxClaim
        }

        let minecraftToken = try await loginMinecraft(uhs: uhs, xstsToken: xsts.token)
        let profile = try await fetchMinecraftProfile(accessToken: minecraftToken.accessToken)

        return LauncherAccount(
            accessToken: minecraftToken.accessToken,
            refreshToken: msToken.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(minecraftToken.expiresIn)),
            username: profile.name,
            uuid: profile.id
        )
    }

    func saveAccount(_ account: LauncherAccount) throws {
        let data = try JSONEncoder().encode(account)
        try KeychainService.save(data, service: "unelaborate.launcher", account: "default")
    }

    func loadAccount() throws -> LauncherAccount? {
        guard let data = try KeychainService.load(service: "unelaborate.launcher", account: "default") else {
            return nil
        }
        return try JSONDecoder().decode(LauncherAccount.self, from: data)
    }

    private func authenticateXboxLive(msAccessToken: String) async throws -> XboxAuthResponse {
        let url = URL(string: "https://user.auth.xboxlive.com/user/authenticate")!
        let payload = XboxAuthRequest(
            properties: .init(authMethod: "RPS", siteName: "user.auth.xboxlive.com", rpsTicket: "d=\(msAccessToken)"),
            relyingParty: "http://auth.xboxlive.com",
            tokenType: "JWT"
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("1", forHTTPHeaderField: "x-xbl-contract-version")
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(XboxAuthResponse.self, from: data)
    }

    private func authenticateXSTS(xblToken: String) async throws -> XSTSAuthResponse {
        let url = URL(string: "https://xsts.auth.xboxlive.com/xsts/authorize")!
        let payload = XSTSAuthRequest(
            properties: .init(sandboxID: "RETAIL", userTokens: [xblToken]),
            relyingParty: "rp://api.minecraftservices.com/",
            tokenType: "JWT"
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("1", forHTTPHeaderField: "x-xbl-contract-version")
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(XSTSAuthResponse.self, from: data)
    }

    private func loginMinecraft(uhs: String, xstsToken: String) async throws -> MinecraftLoginResponse {
        let url = URL(string: "https://api.minecraftservices.com/authentication/login_with_xbox")!
        let payload = MinecraftLoginRequest(identityToken: "XBL3.0 x=\(uhs);\(xstsToken)")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(MinecraftLoginResponse.self, from: data)
    }

    private func fetchMinecraftProfile(accessToken: String) async throws -> MinecraftProfileResponse {
        let url = URL(string: "https://api.minecraftservices.com/minecraft/profile")!
        var req = URLRequest(url: url)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(MinecraftProfileResponse.self, from: data)
    }
}
