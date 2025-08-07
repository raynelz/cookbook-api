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
	}

	func index(req: Request) async throws -> [RecipeDTO] {
		// Проверяем есть ли параметр поиска
		if let searchTitle = req.query[String.self, at: "searchByTitle"] {
			return try await Recipe.query(on: req.db)
				.filter(\.$title ~~ searchTitle)
				.all()
				.map { $0.toDTO() }
		}

		return try await Recipe.query(on: req.db).all().map { $0.toDTO() }
	}

	func create(req: Request) async throws -> RecipeDTO {
		let recipeDTO = try req.content.decode(RecipeDTO.self)
		
		// Проверяем что все обязательные поля переданы
		guard recipeDTO.title != nil,
			  recipeDTO.estimateTime != nil,
			  recipeDTO.calories != nil,
			  recipeDTO.ingredients != nil,
			  recipeDTO.steps != nil else {
			throw Abort(.badRequest, reason: "Missing required fields")
		}
		
		let recipe = recipeDTO.toModel()
		try await recipe.save(on: req.db)
		return recipe.toDTO()
	}

	func show(req: Request) async throws -> RecipeDTO {

		guard let recipe = try await Recipe.find(req.parameters.get("recipeID"), on: req.db) else {
			throw Abort(.notFound)
		}

		return recipe.toDTO()
	}

	func update(req: Request) async throws -> RecipeDTO {
		guard let recipe = try await Recipe.find(req.parameters.get("recipeID"), on: req.db) else {
			throw Abort(.notFound)
		}

		let updateData = try req.content.decode(RecipeDTO.self)

		// Обновляем только переданные поля

		if let title = updateData.title {
			recipe.title = title
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

		try await recipe.update(on: req.db)
		return recipe.toDTO()
	}

	func delete(req: Request) async throws -> HTTPStatus {
		guard let recipe = try await Recipe.find(req.parameters.get("recipeID"), on: req.db) else {
			throw Abort(.notFound)
		}

		try await recipe.delete(on: req.db)
		return .noContent
	}

}
