import Fluent
import Vapor

struct FavoriteRecipeDTO: Content {

	var id: UUID?
	var vkUserId: Int64?
	var recipeId: UUID?
	var createdAt: Date?

	func toModel() -> FavoriteRecipe {
		let model = FavoriteRecipe()
		model.id = self.id
		
		// Для создания проверяем обязательные поля
		guard let vkUserId = self.vkUserId,
			  let recipeId = self.recipeId else {
			fatalError("Required fields missing for favorite recipe creation")
		}
		
		model.vkUserId = vkUserId
		model.$recipe.id = recipeId

		return model
	}

}
