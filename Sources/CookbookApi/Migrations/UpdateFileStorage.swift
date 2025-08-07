import Fluent

struct UpdateFileStorage: AsyncMigration {

	func prepare(on database: any Database) async throws {
		try await database.schema("files")
			.deleteField("data")
			.field("file_path", .string, .required)
			.update()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("files")
			.deleteField("file_path")
			.field("data", .data)
			.update()
	}

}
