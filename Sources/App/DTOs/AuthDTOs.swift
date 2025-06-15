import Vapor

// MARK: - Request DTOs
struct MagicLinkRequest: Content, Validatable {
    let email: String
    
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
    }
}

struct VerifyMagicLinkRequest: Content {
    let token: String
}

// MARK: - Response DTOs
struct MagicLinkResponse: Content {
    let message: String
    let success: Bool
    let expiresIn: Int // 분 단위
}

struct AuthResponse: Content {
    let accessToken: String
    let user: PublicUser
    let expiresIn: Int // 초 단위
}

struct PublicUser: Content {
    let id: UUID
    let email: String
    let name: String
    let isVerified: Bool
    let createdAt: Date?
}

struct ErrorResponse: Content {
    let error: String
    let success: Bool = false
}