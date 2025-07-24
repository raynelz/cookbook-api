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

struct FileUploadResponse: Content {

	let id: UUID
	let filename: String
	let originalName: String
	let size: Int
	let url: String

}
