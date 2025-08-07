import Fluent

struct AddVKUserIdToRecipe: AsyncMigration {

	func prepare(on database: any Database) async throws {
		try await database.schema("recipes")
			.field("vk_user_id", .int64, .required)
			.field("created_at", .datetime)
			.field("updated_at", .datetime)
			.update()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("recipes")
			.deleteField("vk_user_id")
			.deleteField("created_at")
			.deleteField("updated_at")
			.update()
	}

}
