import Fluent

struct CreateFile: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("files")
            .id()
            .field("filename", .string, .required)
            .field("original_name", .string, .required)
            .field("mime_type", .string, .required)
            .field("size", .int, .required)
            .field("data", .data, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("files").delete()
    }
}
