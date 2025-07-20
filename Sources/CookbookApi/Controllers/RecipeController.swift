import Fluent
import Vapor

struct RecipeController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let recipes = routes.grouped("recipes")

        recipes.get(use: self.index)
        recipes.post(use: self.create)
        recipes.group(":recipeID") { recipe in
            recipe.get(use: self.show)
            recipe.patch(use: self.update)
            recipe.delete(use: self.delete)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [RecipeDTO] {
        // Проверяем есть ли параметр поиска
        if let searchTitle = req.query[String.self, at: "searchByTitle"] {
            return try await Recipe.query(on: req.db)
                .filter(\.$title, .custom("ILIKE"), "%\(searchTitle)%")
                .all()
                .map { $0.toDTO() }
        }
        
        return try await Recipe.query(on: req.db).all().map { $0.toDTO() }
    }

    @Sendable
    func create(req: Request) async throws -> RecipeDTO {
        let recipe = try req.content.decode(RecipeDTO.self).toModel()

        try await recipe.save(on: req.db)
        return recipe.toDTO()
    }
    
    @Sendable
    func show(req: Request) async throws -> RecipeDTO {
        guard let recipe = try await Recipe.find(req.parameters.get("recipeID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return recipe.toDTO()
    }
    
    @Sendable
    func update(req: Request) async throws -> RecipeDTO {
        guard let recipe = try await Recipe.find(req.parameters.get("recipeID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let updateData = try req.content.decode(RecipeDTO.self)
        
        if let cover = updateData.cover {
            recipe.cover = cover
        }
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
        
        try await recipe.save(on: req.db)
        return recipe.toDTO()
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let recipe = try await Recipe.find(req.parameters.get("recipeID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await recipe.delete(on: req.db)
        return .noContent
    }
}
