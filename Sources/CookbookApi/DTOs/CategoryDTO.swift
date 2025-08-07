import Fluent
import Vapor

struct CategoryDTO: Content {

	var id: UUID?
	var name: String?
	var createdAt: Date?

	func toModel() -> Category {
		let model = Category()
		model.id = self.id
		
		// Для создания проверяем обязательные поля
		guard let name = self.name else {
			fatalError("Name is required for category creation")
		}
		
		model.name = name

		return model
	}

}
