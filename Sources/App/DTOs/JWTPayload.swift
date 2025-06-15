import JWT
import Vapor

struct UserPayload: JWTPayload {
    let sub: String // user ID
    let email: String
    let name: String
    let isVerified: Bool
    let exp: ExpirationClaim
    let iat: IssuedAtClaim
    let jti: String // JWT ID
    
    init(user: User) {
        self.sub = user.id!.uuidString
        self.email = user.email
        self.name = user.name
        self.isVerified = user.isVerified
        self.iat = IssuedAtClaim(value: Date())
        self.exp = ExpirationClaim(value: Date().addingTimeInterval(24 * 60 * 60)) // 24시간
        self.jti = UUID().uuidString
    }
    
    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
}