import Vapor

struct FileUploadResponse: Content {
	let id: UUID
	let filename: String
	let originalName: String
	let size: Int
	let url: String
}
