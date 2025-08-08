import Fluent
import Foundation

final class Recipe: Model, @unchecked Sendable {

	static let schema = "recipes"

	@ID(key: .id)
	var id: UUID?

	@Field(key: "vk_user_id")
	var vkUserId: Int64

	@Field(key: "title")
	var title: String

	@Field(key: "cover")
	var cover: String?

	@Field(key: "estimate_time")
	var estimateTime: TimeInterval

	@Field(key: "calories")
	var calories: Double

	@Field(key: "ingredients")
	var ingredients: String

	@Field(key: "steps")
	var steps: String

	@Parent(key: "category_id")
	var category: Category

	@Timestamp(key: "created_at", on: .create)
	var createdAt: Date?

	@Timestamp(key: "updated_at", on: .update)
	var updatedAt: Date?

	init() { }

	init(
		id: UUID? = nil,
		vkUserId: Int64,
		title: String,
		cover: String? = nil,
		estimateTime: TimeInterval,
		calories: Double,
		ingredients: String,
		steps: String,
		categoryId: Category.IDValue
	) {
		self.id = id
		self.vkUserId = vkUserId
		self.title = title
		self.cover = cover
		self.estimateTime = estimateTime
		self.calories = calories
		self.ingredients = ingredients
		self.steps = steps
		self.$category.id = categoryId
	}

	func toDTO() -> RecipeDTO {
		.init(
			id: self.id,
			vkUserId: self.vkUserId,
			title: self.title,
			cover: self.cover.flatMap(UUID.init(uuidString:)),
			estimateTime: self.estimateTime,
			calories: self.calories,
			ingredients: self.ingredients,
			steps: self.steps,
			categoryId: self.$category.id,
			createdAt: self.createdAt,
			updatedAt: self.updatedAt
		)
	}

}
