import Fluent
import Vapor

struct UserStatsController: RouteCollection {

	func boot(routes: any RoutesBuilder) throws {
		let stats = routes.grouped("stats")

		stats.get("user", ":vkUserId", use: getUserStats)
		stats.get("top-users", use: getTopUsers)
	}

	// Получить статистику пользователя
	func getUserStats(req: Request) async throws -> UserStatsDTO {
		guard let vkUserId = req.parameters.get("vkUserId", as: Int64.self) else {
			throw Abort(.badRequest, reason: "Invalid vkUserId parameter")
		}

		// Подсчитываем количество рецептов пользователя
		let totalRecipes = try await Recipe.query(on: req.db)
			.filter(\.$vkUserId == vkUserId)
			.count()

		// Подсчитываем количество избранных рецептов
		let favoriteRecipes = try await FavoriteRecipe.query(on: req.db)
			.filter(\.$vkUserId == vkUserId)
			.count()

		return UserStatsDTO(
			vkUserId: vkUserId,
			totalRecipes: totalRecipes,
			favoriteRecipes: favoriteRecipes
		)
	}

	// Получить топ пользователей по количеству рецептов
	func getTopUsers(req: Request) async throws -> [UserStatsDTO] {
		let limit = req.query[Int.self, at: "limit"] ?? 10
		
		// Получаем всех пользователей с их количеством рецептов
		let recipes = try await Recipe.query(on: req.db).all()
		
		// Группируем по пользователю и считаем количество рецептов
		var userRecipeCounts: [Int64: Int] = [:]
		for recipe in recipes {
			userRecipeCounts[recipe.vkUserId, default: 0] += 1
		}
		
		// Сортируем по количеству рецептов и берем топ
		let topUserIds = userRecipeCounts
			.sorted { $0.value > $1.value }
			.prefix(limit)
			.map { $0.key }

		var result: [UserStatsDTO] = []

		for vkUserId in topUserIds {
			// Получаем полную статистику для каждого пользователя
			let stats = try await getUserStatsForId(vkUserId, on: req.db)
			result.append(stats)
		}

		return result
	}

	// Вспомогательный метод для получения статистики пользователя
	private func getUserStatsForId(_ vkUserId: Int64, on db: any Database) async throws -> UserStatsDTO {
		let totalRecipes = try await Recipe.query(on: db)
			.filter(\.$vkUserId == vkUserId)
			.count()

		let favoriteRecipes = try await FavoriteRecipe.query(on: db)
			.filter(\.$vkUserId == vkUserId)
			.count()

		return UserStatsDTO(
			vkUserId: vkUserId,
			totalRecipes: totalRecipes,
			favoriteRecipes: favoriteRecipes
		)
	}

}
