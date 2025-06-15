import Vapor

enum MagicLinkError: Error, AbortError {
    case invalidToken
    case expiredToken
    case usedToken
    case userNotFound
    case rateLimitExceeded
    case emailSendingFailed
    
    var status: HTTPResponseStatus {
        switch self {
        case .invalidToken, .expiredToken, .usedToken:
            return .unauthorized
        case .userNotFound:
            return .notFound
        case .rateLimitExceeded:
            return .tooManyRequests
        case .emailSendingFailed:
            return .internalServerError
        }
    }
    
    var reason: String {
        switch self {
        case .invalidToken:
            return "유효하지 않은 인증 토큰입니다."
        case .expiredToken:
            return "인증 토큰이 만료되었습니다."
        case .usedToken:
            return "이미 사용된 인증 토큰입니다."
        case .userNotFound:
            return "등록되지 않은 이메일입니다."
        case .rateLimitExceeded:
            return "너무 많은 요청입니다. 잠시 후 다시 시도해주세요."
        case .emailSendingFailed:
            return "이메일 전송에 실패했습니다."
        }
    }
}