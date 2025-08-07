import Fluent
import Foundation

final class FileModel: Model, @unchecked Sendable {

	static let schema = "files"

	@ID(key: .id)
	var id: UUID?

	@Field(key: "filename")
	var filename: String

	@Field(key: "original_name")
	var originalName: String

	@Field(key: "mime_type")
	var mimeType: String

	@Field(key: "size")
	var size: Int

	@Field(key: "file_path")
	var filePath: String

	@Timestamp(key: "created_at", on: .create)
	var createdAt: Date?

	init() { }

	init(
		id: UUID? = nil,
		filename: String,
		originalName: String,
		mimeType: String,
		size: Int,
		filePath: String
	) {
		self.id = id
		self.filename = filename
		self.originalName = originalName
		self.mimeType = mimeType
		self.size = size
		self.filePath = filePath
	}

	func toDTO() -> FileDTO {
		.init(
			id: self.id,
			filename: self.filename,
			originalName: self.originalName,
			mimeType: self.mimeType,
			size: self.size,
			url: "/api/v1/files/\(self.id?.uuidString ?? "")"
		)
	}

}
