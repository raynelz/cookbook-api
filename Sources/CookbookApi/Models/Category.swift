import Fluent
import Foundation

final class Category: Model, @unchecked Sendable {

	static let schema = "categories"

	@ID(key: .id)
	var id: UUID?

	@Field(key: "name")
	var name: String

	@Timestamp(key: "created_at", on: .create)
	var createdAt: Date?

	init() { }

	init(
		id: UUID? = nil,
		name: String
	) {
		self.id = id
		self.name = name
	}

	func toDTO() -> CategoryDTO {
		.init(
			id: self.id,
			name: self.name,
			createdAt: self.createdAt
		)
	}

}
