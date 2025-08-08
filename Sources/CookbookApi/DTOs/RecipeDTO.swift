import Fluent
import Vapor

struct RecipeDTO: Content {

	var id: UUID?
	var vkUserId: Int64?
	var title: String?
	var cover: UUID?
	var estimateTime: TimeInterval?
	var calories: Double?
	var ingredients: String?
	var steps: String?
	var categoryId: UUID?
	var createdAt: Date?
	var updatedAt: Date?

	func toModel() -> Recipe {
		let model = Recipe()
		model.id = self.id
		
		// Для создания проверяем обязательные поля
		guard let vkUserId = self.vkUserId,
			  let title = self.title,
			  let estimateTime = self.estimateTime,
			  let calories = self.calories,
			  let ingredients = self.ingredients,
			  let steps = self.steps,
			  let categoryId = self.categoryId else {
			fatalError("Required fields missing for recipe creation")
		}
		
		model.vkUserId = vkUserId
		model.title = title
		model.cover = self.cover?.uuidString
		model.estimateTime = estimateTime
		model.calories = calories
		model.ingredients = ingredients
		model.steps = steps
		model.$category.id = categoryId

		return model
	}

}