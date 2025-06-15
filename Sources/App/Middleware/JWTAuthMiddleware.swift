import Vapor
import JWT

struct JWTAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let bearerToken = request.headers.bearerAuthorization?.token else {
            throw MagicLinkError.invalidToken
        }
        
        do {
            let payload = try request.jwt.verify(bearerToken, as: UserPayload.self)
            request.auth.login(payload)
            return try await next.respond(to: request)
        } catch {
            throw MagicLinkError.invalidToken
        }
    }
}