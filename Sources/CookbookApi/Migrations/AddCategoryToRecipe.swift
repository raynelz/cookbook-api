import Fluent

struct AddCategoryToRecipe: AsyncMigration {

	func prepare(on database: any Database) async throws {
		try await database.schema("recipes")
			.field("category_id", .uuid, .references("categories", "id", onDelete: .restrict))
			.update()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("recipes")
			.deleteField("category_id")
			.update()
	}

}
