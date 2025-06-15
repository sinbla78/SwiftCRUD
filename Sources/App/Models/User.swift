import Vapor
import Fluent

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "is_verified")
    var isVerified: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Children(for: \.$user)
    var magicLinks: [MagicLink]
    
    init() { }
    
    init(id: UUID? = nil, email: String, name: String, isVerified: Bool = false) {
        self.id = id
        self.email = email
        self.name = name
        self.isVerified = isVerified
    }
}

extension User {
    func toPublicUser() -> PublicUser {
        return PublicUser(
            id: self.id!,
            email: self.email,
            name: self.name,
            isVerified: self.isVerified,
            createdAt: self.createdAt
        )
    }
}