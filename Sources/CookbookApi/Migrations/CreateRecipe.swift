import Fluent

struct CreateRecipe: AsyncMigration {

	func prepare(on database: any Database) async throws {
		try await database.schema("recipes")
			.id()
			.field("title", .string, .required)
			.field("estimate_time", .double, .required)
			.field("calories", .double, .required)
			.field("ingredients", .string, .required)
			.field("steps", .string, .required)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("recipes").delete()
	}

}