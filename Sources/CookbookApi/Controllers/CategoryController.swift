import Fluent
import Vapor

struct CategoryController: RouteCollection {

	func boot(routes: any RoutesBuilder) throws {
		let categories = routes.grouped("categories")

		categories.get(use: index)
		categories.post(use: create)
		categories.group(":categoryID") { category in
			category.get(use: show)
			category.patch(use: update)
			category.delete(use: delete)
		}
	}

	func index(req: Request) async throws -> [CategoryDTO] {
		return try await Category.query(on: req.db)
			.sort(\.$name)
			.all()
			.map { $0.toDTO() }
	}

	func create(req: Request) async throws -> CategoryDTO {
		let categoryDTO = try req.content.decode(CategoryDTO.self)
		
		// Проверяем что обязательные поля переданы
		guard categoryDTO.name != nil else {
			throw Abort(.badRequest, reason: "Name is required")
		}
		
		let category = categoryDTO.toModel()
		try await category.save(on: req.db)
		return category.toDTO()
	}

	func show(req: Request) async throws -> CategoryDTO {
		guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else {
			throw Abort(.notFound)
		}

		return category.toDTO()
	}

	func update(req: Request) async throws -> CategoryDTO {
		guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else {
			throw Abort(.notFound)
		}

		let updateData = try req.content.decode(CategoryDTO.self)

		// Обновляем только переданные поля
		if let name = updateData.name {
			category.name = name
		}

		try await category.update(on: req.db)
		return category.toDTO()
	}

	func delete(req: Request) async throws -> HTTPStatus {
		guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else {
			throw Abort(.notFound)
		}

		// Проверяем, есть ли рецепты в этой категории
		let recipeCount = try await Recipe.query(on: req.db)
			.filter(\.$category.$id == category.id!)
			.count()
		
		if recipeCount > 0 {
			throw Abort(.badRequest, reason: "Cannot delete category with existing recipes")
		}

		try await category.delete(on: req.db)
		return .noContent
	}

}
