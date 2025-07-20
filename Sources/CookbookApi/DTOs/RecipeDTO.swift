import Fluent
import Vapor

struct RecipeDTO: Content {
    var id: UUID?
    var cover: String?
    var title: String?
    var estimateTime: TimeInterval?
    var calories: Double?
    var ingredients: String?
    var steps: String?
    
    func toModel() -> Recipe {
        let model = Recipe()
        
        model.id = self.id
        if let cover = self.cover {
            model.cover = cover
        }
        if let title = self.title {
            model.title = title
        }
        if let estimateTime = self.estimateTime {
            model.estimateTime = estimateTime
        }
        if let calories = self.calories {
            model.calories = calories
        }
        if let ingredients = self.ingredients {
            model.ingredients = ingredients
        }
        if let steps = self.steps {
            model.steps = steps
        }
        return model
    }
}