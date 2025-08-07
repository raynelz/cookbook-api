import Fluent
import Vapor

struct FileDTO: Content {

	var id: UUID?
	var filename: String?
	var originalName: String?
	var mimeType: String?
	var size: Int?
	var url: String?

}
