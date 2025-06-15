import Fluent
import FluentMySQLDriver
import Vapor
import JWT

public func configure(_ app: Application) async throws {
    // 환경 설정
    app.logger.logLevel = app.environment == .production ? .notice : .debug
    
    // MySQL 데이터베이스 설정
    app.databases.use(.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 3306,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_user",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "swiftcrud"
    ), as: .mysql)
    
    // JWT 설정
    let jwtSecret = Environment.get("JWT_SECRET") ?? "your-super-secret-jwt-key"
    app.jwt.signers.use(.hs256(key: jwtSecret))
    
    // 마이그레이션 등록
    app.migrations.add(CreateUser())
    app.migrations.add(CreateMagicLink())
    
    // 컨트롤러 등록
    try app.register(collection: AuthController())
    
    // 기본 라우트
    app.get { req async in
        "swiftCRUD Magic Link Auth API 🔗✨"
    }
    
    app.get("health") { req async in
        return [
            "status": "healthy",
            "timestamp": Date(),
            "version": "1.0.0"
        ]
    }
    
    // 개발 환경에서 자동 마이그레이션
    if app.environment == .development {
        try await app.autoMigrate()
    }
}