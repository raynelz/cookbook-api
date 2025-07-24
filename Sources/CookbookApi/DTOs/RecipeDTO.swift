import Fluent
import Vapor

struct RecipeDTO: Content {

	var id: UUID?
	var cover: String?
	var title: String?
	var estimateTime: TimeInterval?
	var calories: Double?
	var ingredients: String?
	var steps: String?

	func toModel() -> Recipe {
		let model = Recipe()
		model.id = self.id
		
		// Для создания проверяем обязательные поля
		guard let cover = self.cover,
			  let title = self.title,
			  let estimateTime = self.estimateTime,
			  let calories = self.calories,
			  let ingredients = self.ingredients,
			  let steps = self.steps else {
			fatalError("Required fields missing for recipe creation")
		}
		
		model.cover = cover
		model.title = title
		model.estimateTime = estimateTime
		model.calories = calories
		model.ingredients = ingredients
		model.steps = steps

		return model
	}

}