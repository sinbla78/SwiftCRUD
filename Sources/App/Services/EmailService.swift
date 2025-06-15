import Vapor
import Leaf

protocol EmailServiceProtocol {
    func sendMagicLinkEmail(to user: User, magicLink: MagicLink, baseURL: String) async throws
}

class EmailService: EmailServiceProtocol {
    static let shared = EmailService()
    
    private init() {}
    
    func sendMagicLinkEmail(to user: User, magicLink: MagicLink, baseURL: String) async throws {
        let magicLinkURL = "\(baseURL)/auth/verify?token=\(magicLink.token)"
        
        let emailData = MagicLinkEmailData(
            userName: user.name,
            magicLinkURL: magicLinkURL,
            purpose: magicLink.purpose,
            expirationMinutes: getExpirationMinutes(for: magicLink.purpose)
        )
        
        // 실제 환경에서는 여기서 실제 이메일 서비스 호출
        // SendGrid, AWS SES, Mailgun 등 사용
        
        print("📧 매직링크 이메일 전송")
        print("받는 사람: \(user.email)")
        print("제목: \(getEmailSubject(for: magicLink.purpose))")
        print("매직링크: \(magicLinkURL)")
        print("만료시간: \(emailData.expirationMinutes)분")
        print("---")
        
        // TODO: 실제 이메일 전송 구현
        // await sendEmailViaProvider(emailData)
    }
    
    private func getEmailSubject(for purpose: MagicLinkPurpose) -> String {
        switch purpose {
        case .login:
            return "로그인 링크"
        case .signup:
            return "회원가입 완료"
        case .emailVerification:
            return "이메일 인증"
        }
    }
    
    private func getExpirationMinutes(for purpose: MagicLinkPurpose) -> Int {
        switch purpose {
        case .login:
            return 15
        case .signup:
            return 60
        case .emailVerification:
            return 24 * 60
        }
    }
}

struct MagicLinkEmailData {
    let userName: String
    let magicLinkURL: String
    let purpose: MagicLinkPurpose
    let expirationMinutes: Int
}