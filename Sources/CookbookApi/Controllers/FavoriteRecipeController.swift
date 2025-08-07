import Fluent
import Vapor

struct FavoriteRecipeController: RouteCollection {

	func boot(routes: any RoutesBuilder) throws {
		let favorites = routes.grouped("favorites")

		favorites.get(use: getUserFavorites)
		favorites.post(use: addToFavorites)
		favorites.delete(":recipeID", use: removeFromFavorites)
		favorites.get("check", ":recipeID", use: checkIfFavorite)
	}

	// Получить все избранные рецепты пользователя
	func getUserFavorites(req: Request) async throws -> [RecipeDTO] {
		guard let vkUserId = req.query[Int64.self, at: "vkUserId"] else {
			throw Abort(.badRequest, reason: "vkUserId parameter is required")
		}

		return try await FavoriteRecipe.query(on: req.db)
			.filter(\.$vkUserId == vkUserId)
			.with(\.$recipe) // Загружаем связанные рецепты
			.sort(\.$createdAt, .descending)
			.all()
			.map { $0.recipe.toDTO() }
	}

	// Добавить рецепт в избранное
	func addToFavorites(req: Request) async throws -> FavoriteRecipeDTO {
		let favoriteDTO = try req.content.decode(FavoriteRecipeDTO.self)
		
		// Проверяем что все обязательные поля переданы
		guard favoriteDTO.vkUserId != nil,
			  favoriteDTO.recipeId != nil else {
			throw Abort(.badRequest, reason: "Missing required fields")
		}
		
		// Проверяем что рецепт существует
		guard let _ = try await Recipe.find(favoriteDTO.recipeId, on: req.db) else {
			throw Abort(.notFound, reason: "Recipe not found")
		}
		
		// Проверяем что рецепт еще не в избранном
		let existingFavorite = try await FavoriteRecipe.query(on: req.db)
			.filter(\.$vkUserId == favoriteDTO.vkUserId!)
			.filter(\.$recipe.$id == favoriteDTO.recipeId!)
			.first()
		
		if existingFavorite != nil {
			throw Abort(.conflict, reason: "Recipe already in favorites")
		}
		
		let favorite = favoriteDTO.toModel()
		try await favorite.save(on: req.db)
		return favorite.toDTO()
	}

	// Удалить рецепт из избранного
	func removeFromFavorites(req: Request) async throws -> HTTPStatus {
		guard let recipeId = req.parameters.get("recipeID", as: UUID.self),
			  let vkUserId = req.query[Int64.self, at: "vkUserId"] else {
			throw Abort(.badRequest, reason: "recipeID and vkUserId are required")
		}

		guard let favorite = try await FavoriteRecipe.query(on: req.db)
			.filter(\.$vkUserId == vkUserId)
			.filter(\.$recipe.$id == recipeId)
			.first() else {
			throw Abort(.notFound, reason: "Favorite recipe not found")
		}

		try await favorite.delete(on: req.db)
		return .noContent
	}

	// Проверить, добавлен ли рецепт в избранное
	func checkIfFavorite(req: Request) async throws -> [String: Bool] {
		guard let recipeId = req.parameters.get("recipeID", as: UUID.self),
			  let vkUserId = req.query[Int64.self, at: "vkUserId"] else {
			throw Abort(.badRequest, reason: "recipeID and vkUserId are required")
		}

		let favorite = try await FavoriteRecipe.query(on: req.db)
			.filter(\.$vkUserId == vkUserId)
			.filter(\.$recipe.$id == recipeId)
			.first()

		return ["isFavorite": favorite != nil]
	}

}
