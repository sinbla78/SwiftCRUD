import Foundation
import Crypto

struct TokenGenerator {
    static func generateSecureToken(length: Int = 32) -> String {
        let bytes = [UInt8].random(count: length)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    static func generateURLSafeToken() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}