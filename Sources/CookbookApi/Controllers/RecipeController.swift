import Fluent
import Vapor

struct RecipeController: RouteCollection {

	func boot(routes: any RoutesBuilder) throws {
		let recipes = routes.grouped("recipes")

		recipes.get(use: index)
		recipes.post(use: create)
		recipes.group(":recipeID") { recipe in
			recipe.get(use: show)
			recipe.patch(use: update)
			recipe.delete(use: delete)
		}

		recipes.get("user", ":vkUserId", use: getUserRecipes)
	}

	// Фильтры (query параметры)
	func index(req: Request) async throws -> [RecipeDTO] {
		var query = Recipe.query(on: req.db)

		// Проверяем есть ли параметр поиска
		if let searchTitle = req.query[String.self, at: "searchByTitle"] {
			query = query.filter(\.$title ~~ searchTitle)
		}

		// Фильтрация по пользователю
		if let vkUserId = req.query[Int64.self, at: "vkUserId"] {
			query = query.filter(\.$vkUserId == vkUserId)
		}

		// Фильтрация по категории
		if let categoryId = req.query[UUID.self, at: "categoryId"] {
			query = query.filter(\.$category.$id == categoryId)
		}

		// Фильтрация по времени приготовления
		if let estimateTime = req.query[TimeInterval.self, at: "estimateTime"] {
			query = query.filter(\.$estimateTime == estimateTime)
		}

		// Сортировка по дате создания (новые сначала)
		query = query.sort(\.$createdAt, .descending)
		
		return try await query.all().map { $0.toDTO() }
	}

	// Создаём рецепт
	func create(req: Request) async throws -> RecipeDTO {
		let recipeDTO = try req.content.decode(RecipeDTO.self)

		guard recipeDTO.vkUserId != nil,
			  recipeDTO.title != nil,
			  recipeDTO.estimateTime != nil,
			  recipeDTO.calories != nil,
			  recipeDTO.ingredients != nil,
			  recipeDTO.steps != nil,
			  recipeDTO.categoryId != nil else {
			throw Abort(.badRequest, reason: "Missing required fields")
		}

		guard let _ = try await Category.find(recipeDTO.categoryId, on: req.db) else {
			throw Abort(.badRequest, reason: "Category not found")
		}

		let recipe = recipeDTO.toModel()
		try await recipe.save(on: req.db)
		return recipe.toDTO()
	}

	// Получаем рецепт по id
	func show(req: Request) async throws -> RecipeDTO {

		guard let recipe = try await Recipe.find(req.parameters.get("recipeID"), on: req.db) else {
			throw Abort(.notFound)
		}

		return recipe.toDTO()
	}

	// Обновляем рецепт по id
	func update(req: Request) async throws -> RecipeDTO {
		guard let recipe = try await Recipe.find(req.parameters.get("recipeID"), on: req.db) else {
			throw Abort(.notFound)
		}

		let updateData = try req.content.decode(RecipeDTO.self)

		if let title = updateData.title {
			recipe.title = title
		}
		if let cover = updateData.cover {
			recipe.cover = cover
		}
		if let estimateTime = updateData.estimateTime {
			recipe.estimateTime = estimateTime
		}
		if let calories = updateData.calories {
			recipe.calories = calories
		}
		if let ingredients = updateData.ingredients {
			recipe.ingredients = ingredients
		}
		if let steps = updateData.steps {
			recipe.steps = steps
		}
		if let categoryId = updateData.categoryId {
			// Проверяем что категория существует
			guard let _ = try await Category.find(categoryId, on: req.db) else {
				throw Abort(.badRequest, reason: "Category not found")
			}
			recipe.$category.id = categoryId
		}

		try await recipe.update(on: req.db)
		return recipe.toDTO()
	}

	// Удаление рецепта по id
	func delete(req: Request) async throws -> HTTPStatus {
		guard let recipe = try await Recipe.find(req.parameters.get("recipeID"), on: req.db) else {
			throw Abort(.notFound)
		}

		try await recipe.delete(on: req.db)
		return .noContent
	}
	
	// Получение рецептов конкретного пользователя
	func getUserRecipes(req: Request) async throws -> [RecipeDTO] {
		guard let vkUserId = req.parameters.get("vkUserId", as: Int64.self) else {
			throw Abort(.badRequest, reason: "Invalid vkUserId parameter")
		}
		
		return try await Recipe.query(on: req.db)
			.filter(\.$vkUserId == vkUserId)
			.sort(\.$createdAt, .descending)
			.all()
			.map { $0.toDTO() }
	}

}
