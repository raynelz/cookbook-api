import Fluent
import Foundation

final class FavoriteRecipe: Model, @unchecked Sendable {

	static let schema = "favorite_recipes"

	@ID(key: .id)
	var id: UUID?

	@Field(key: "vk_user_id")
	var vkUserId: Int64

	@Parent(key: "recipe_id")
	var recipe: Recipe

	@Timestamp(key: "created_at", on: .create)
	var createdAt: Date?

	init() { }

	init(
		id: UUID? = nil,
		vkUserId: Int64,
		recipeId: Recipe.IDValue
	) {
		self.id = id
		self.vkUserId = vkUserId
		self.$recipe.id = recipeId
	}

	func toDTO() -> FavoriteRecipeDTO {
		.init(
			id: self.id,
			vkUserId: self.vkUserId,
			recipeId: self.$recipe.id,
			createdAt: self.createdAt
		)
	}

}
