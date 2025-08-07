import Fluent

struct RemoveCoverFromRecipe: AsyncMigration {

	func prepare(on database: any Database) async throws {
		try await database.schema("recipes")
			.deleteField("cover")
			.update()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("recipes")
			.field("cover", .string, .required)
			.update()
	}

}
