import Vapor
import JWT

struct AuthController: RouteCollection {
    private let magicLinkService: MagicLinkServiceProtocol
    
    init(magicLinkService: MagicLinkServiceProtocol = MagicLinkService()) {
        self.magicLinkService = magicLinkService
    }
    
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        
        // Public routes
        auth.post("login", use: requestLoginLink)
        auth.post("signup", use: requestSignupLink)
        auth.post("verify", use: verifyMagicLink)
        
        // Protected routes
        let protected = auth.grouped(JWTAuthMiddleware())
        protected.get("me", use: getCurrentUser)
        protected.post("resend-verification", use: resendEmailVerification)
    }
    
    // 로그인 매직링크 요청
    func requestLoginLink(req: Request) async throws -> MagicLinkResponse {
        let loginRequest = try req.content.decode(MagicLinkRequest.self)
        try MagicLinkRequest.validate(content: req)
        
        return try await magicLinkService.sendMagicLink(
            email: loginRequest.email,
            purpose: .login,
            on: req.db,
            request: req
        )
    }
    
    // 회원가입 매직링크 요청
    func requestSignupLink(req: Request) async throws -> MagicLinkResponse {
        let signupRequest = try req.content.decode(MagicLinkRequest.self)
        try MagicLinkRequest.validate(content: req)
        
        return try await magicLinkService.sendMagicLink(
            email: signupRequest.email,
            purpose: .signup,
            on: req.db,
            request: req
        )
    }
    
    // 매직링크 검증
    func verifyMagicLink(req: Request) async throws -> AuthResponse {
        let verifyRequest = try req.content.decode(VerifyMagicLinkRequest.self)
        
        return try await magicLinkService.verifyMagicLink(
            token: verifyRequest.token,
            on: req.db,
            jwt: req.jwt.signers.get()!
        )
    }
    
    // 현재 사용자 정보
    func getCurrentUser(req: Request) async throws -> PublicUser {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let userId = UUID(uuidString: payload.sub),
              let user = try await User.find(userId, on: req.db) else {
            throw MagicLinkError.userNotFound
        }
        
        return user.toPublicUser()
    }
    
    // 이메일 인증 재전송
    func resendEmailVerification(req: Request) async throws -> MagicLinkResponse {
        let payload = try req.auth.require(UserPayload.self)
        
        guard !payload.isVerified else {
            throw Abort(.badRequest, reason: "이미 인증된 이메일입니다.")
        }
        
        return try await magicLinkService.sendMagicLink(
            email: payload.email,
            purpose: .emailVerification,
            on: req.db,
            request: req
        )
    }
}
