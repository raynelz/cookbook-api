import Fluent

struct CreateFavoriteRecipe: AsyncMigration {

	func prepare(on database: any Database) async throws {
		try await database.schema("favorite_recipes")
			.id()
			.field("vk_user_id", .int64, .required)
			.field("recipe_id", .uuid, .required, .references("recipes", "id", onDelete: .cascade))
			.field("created_at", .datetime)
			.unique(on: "vk_user_id", "recipe_id") // Предотвращаем дублирование
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("favorite_recipes").delete()
	}

}
