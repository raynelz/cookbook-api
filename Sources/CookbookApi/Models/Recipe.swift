import Fluent
import Foundation

final class Recipe: Model, @unchecked Sendable {

	static let schema = "recipes"

	@ID(key: .id)
	var id: UUID?

	@Field(key: "title")
	var title: String

	@Field(key: "estimate_time")
	var estimateTime: TimeInterval

	@Field(key: "calories")
	var calories: Double

	@Field(key: "ingredients")
	var ingredients: String

	@Field(key: "steps")
	var steps: String

	init() { }

	init(
		id: UUID? = nil,
		title: String,
		estimateTime: TimeInterval,
		calories: Double,
		ingredients: String,
		steps: String
	) {
		self.id = id
		self.title = title
		self.estimateTime = estimateTime
		self.calories = calories
		self.ingredients = ingredients
		self.steps = steps
	}

	func toDTO() -> RecipeDTO {
		.init(
			id: self.id,
			title: self.title,
			estimateTime: self.estimateTime,
			calories: self.calories,
			ingredients: self.ingredients,
			steps: self.steps
		)
	}

}
