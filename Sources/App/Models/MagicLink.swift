import Vapor
import Fluent

final class MagicLink: Model, Content {
    static let schema = "magic_links"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "token")
    var token: String
    
    @Field(key: "purpose")
    var purpose: MagicLinkPurpose
    
    @Field(key: "expires_at")
    var expiresAt: Date
    
    @Field(key: "used_at")
    var usedAt: Date?
    
    @Field(key: "ip_address")
    var ipAddress: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        userID: UUID,
        token: String,
        purpose: MagicLinkPurpose,
        expiresAt: Date,
        ipAddress: String? = nil
    ) {
        self.id = id
        self.$user.id = userID
        self.token = token
        self.purpose = purpose
        self.expiresAt = expiresAt
        self.ipAddress = ipAddress
    }
}

enum MagicLinkPurpose: String, Codable, CaseIterable {
    case login = "login"
    case signup = "signup"
    case emailVerification = "email_verification"
}

extension MagicLink {
    var isExpired: Bool {
        return Date() > expiresAt
    }
    
    var isUsed: Bool {
        return usedAt != nil
    }
    
    var isValid: Bool {
        return !isUsed && !isExpired
    }
}