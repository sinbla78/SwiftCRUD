import Vapor
import Fluent

protocol MagicLinkServiceProtocol {
    func sendMagicLink(email: String, purpose: MagicLinkPurpose, on db: Database, request: Request) async throws -> MagicLinkResponse
    func verifyMagicLink(token: String, on db: Database, jwt: JWTSigner) async throws -> AuthResponse
}

struct MagicLinkService: MagicLinkServiceProtocol {
    
    func sendMagicLink(email: String, purpose: MagicLinkPurpose, on db: Database, request: Request) async throws -> MagicLinkResponse {
        
        // 기존 사용자 찾기 또는 신규 사용자 생성
        let user: User
        if let existingUser = try await User.query(on: db).filter(\.$email == email).first() {
            user = existingUser
        } else {
            // 신규 사용자 생성 (signup 목적일 때만)
            guard purpose == .signup else {
                throw MagicLinkError.userNotFound
            }
            user = User(email: email, name: extractNameFromEmail(email))
            try await user.save(on: db)
        }
        
        // 기존 미사용 매직링크 정리 (같은 목적)
        try await MagicLink.query(on: db)
            .filter(\.$user.$id == user.id!)
            .filter(\.$purpose == purpose)
            .filter(\.$usedAt == .null)
            .delete()
        
        // 새 매직링크 생성
        let token = TokenGenerator.generateSecureToken()
        let expirationMinutes = getExpirationMinutes(for: purpose)
        let expiresAt = Date().addingTimeInterval(TimeInterval(expirationMinutes * 60))
        
        let magicLink = MagicLink(
            userID: user.id!,
            token: token,
            purpose: purpose,
            expiresAt: expiresAt,
            ipAddress: request.remoteAddress?.ipAddress
        )
        try await magicLink.save(on: db)
        
        // 이메일 전송
        try await EmailService.shared.sendMagicLinkEmail(
            to: user,
            magicLink: magicLink,
            baseURL: getBaseURL(from: request)
        )
        
        return MagicLinkResponse(
            message: getMagicLinkMessage(for: purpose),
            success: true,
            expiresIn: expirationMinutes
        )
    }
    
    func verifyMagicLink(token: String, on db: Database, jwt: JWTSigner) async throws -> AuthResponse {
        guard let magicLink = try await MagicLink.query(on: db)
            .filter(\.$token == token)
            .with(\.$user)
            .first() else {
            throw MagicLinkError.invalidToken
        }
        
        // 토큰 유효성 검사
        guard magicLink.isValid else {
            if magicLink.isExpired {
                throw MagicLinkError.expiredToken
            } else {
                throw MagicLinkError.usedToken
            }
        }
        
        // 매직링크 사용 처리
        magicLink.usedAt = Date()
        try await magicLink.save(on: db)
        
        // 이메일 인증 처리 (signup 또는 email_verification 목적인 경우)
        if magicLink.purpose == .signup || magicLink.purpose == .emailVerification {
            magicLink.user.isVerified = true
            try await magicLink.user.save(on: db)
        }
        
        // JWT 토큰 생성
        let payload = UserPayload(user: magicLink.user)
        let accessToken = try jwt.sign(payload)
        
        return AuthResponse(
            accessToken: accessToken,
            user: magicLink.user.toPublicUser(),
            expiresIn: 24 * 60 * 60 // 24시간 (초 단위)
        )
    }
    
    // MARK: - Private Methods
    private func extractNameFromEmail(_ email: String) -> String {
        return String(email.split(separator: "@").first ?? "User")
    }
    
    private func getExpirationMinutes(for purpose: MagicLinkPurpose) -> Int {
        switch purpose {
        case .login:
            return 15 // 15분
        case .signup:
            return 60 // 1시간
        case .emailVerification:
            return 24 * 60 // 24시간
        }
    }
    
    private func getMagicLinkMessage(for purpose: MagicLinkPurpose) -> String {
        switch purpose {
        case .login:
            return "로그인 매직링크가 이메일로 전송되었습니다."
        case .signup:
            return "회원가입 매직링크가 이메일로 전송되었습니다."
        case .emailVerification:
            return "이메일 인증 링크가 전송되었습니다."
        }
    }
    
    private func getBaseURL(from request: Request) -> String {
        return Environment.get("APP_URL") ?? "http://localhost:8080"
    }
}