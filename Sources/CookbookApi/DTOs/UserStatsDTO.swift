import Vapor

struct UserStatsDTO: Content {
	let vkUserId: Int64
	let totalRecipes: Int
	let favoriteRecipes: Int
}

struct RecipeStatsDTO: Content {
	let recipeId: UUID
	let averageRating: Double
	let totalRatings: Int
	let userRating: Int?
}
