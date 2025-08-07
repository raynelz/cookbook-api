import Fluent
import Vapor

func routes(_ app: Application) throws {

	let api = app.grouped("api", "v1")

	try api.register(collection: RecipeController())
	try api.register(collection: FileController())
	try api.register(collection: FavoriteRecipeController())
	try api.register(collection: CategoryController())
	try api.register(collection: UserStatsController())

}
