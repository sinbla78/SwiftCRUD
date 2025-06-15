import Fluent

struct CreateMagicLink: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("magic_links")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("token", .string, .required)
            .field("purpose", .string, .required)
            .field("expires_at", .datetime, .required)
            .field("used_at", .datetime)
            .field("ip_address", .string)
            .field("created_at", .datetime)
            .unique(on: "token")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("magic_links").delete()
    }
}