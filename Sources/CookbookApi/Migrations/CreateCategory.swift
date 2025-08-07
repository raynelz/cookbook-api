import Fluent

struct CreateCategory: AsyncMigration {

	func prepare(on database: any Database) async throws {
		try await database.schema("categories")
			.id()
			.field("name", .string, .required)
			.field("description", .string)
			.field("icon", .string)
			.field("created_at", .datetime)
			.unique(on: "name") // Уникальные названия категорий
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("categories").delete()
	}

}
