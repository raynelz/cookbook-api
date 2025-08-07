import Fluent

struct AddCoverToRecipe: AsyncMigration {

    func prepare(on database: any Database) async throws {
        try await database.schema("recipes")
            .field("cover", .string)
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("recipes")
            .deleteField("cover")
            .update()
    }

}
