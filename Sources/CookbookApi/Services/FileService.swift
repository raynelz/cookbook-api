import Vapor
import Foundation

struct FileService {
	
	private let uploadDirectory: String
	private let maxFileSize: Int
	private let allowedTypes: [String]
	
	init() {
		// Получаем путь для загрузки файлов из переменных окружения
		self.uploadDirectory = Environment.get("UPLOAD_DIRECTORY") ?? "Public/uploads"
		self.maxFileSize = Environment.get("MAX_FILE_SIZE").flatMap(Int.init) ?? 10 * 1024 * 1024 // 10MB по умолчанию
		self.allowedTypes = Environment.get("ALLOWED_FILE_TYPES")?.split(separator: ",").map(String.init) ?? ["image/jpeg", "image/png", "image/gif", "image/webp"]
		
		// Создаем директорию если её нет
		createUploadDirectoryIfNeeded()
	}
	
	private func createUploadDirectoryIfNeeded() {
		let fileManager = FileManager.default
		if !fileManager.fileExists(atPath: uploadDirectory) {
			try? fileManager.createDirectory(atPath: uploadDirectory, withIntermediateDirectories: true)
		}
	}
	
	func saveFile(_ file: File) throws -> (filename: String, filePath: String) {
		// Валидируем размер файла
		guard file.data.readableBytes <= maxFileSize else {
			let maxSizeMB = maxFileSize / 1024 / 1024
			throw Abort(.payloadTooLarge, reason: "File too large. Maximum size is \(maxSizeMB)MB")
		}
		
		// Определяем MIME тип
		let mimeType = file.contentType?.description ?? "application/octet-stream"
		
		// Проверяем разрешенные типы файлов
		guard allowedTypes.contains(mimeType) else {
			throw Abort(.badRequest, reason: "File type not allowed. Allowed types: \(allowedTypes.joined(separator: ", "))")
		}
		
		// Генерируем уникальное имя файла
		let fileExtension = file.extension ?? "jpg"
		let filename = "\(UUID().uuidString).\(fileExtension)"
		let filePath = "\(uploadDirectory)/\(filename)"
		
		// Сохраняем файл на диск
		let fileData = Data(buffer: file.data)
		try fileData.write(to: URL(fileURLWithPath: filePath))
		
		return (filename: filename, filePath: filePath)
	}
	
	func getFileData(filePath: String) throws -> Data {
		let url = URL(fileURLWithPath: filePath)
		return try Data(contentsOf: url)
	}
	
	func deleteFile(filePath: String) throws {
		let fileManager = FileManager.default
		if fileManager.fileExists(atPath: filePath) {
			try fileManager.removeItem(atPath: filePath)
		}
	}
	
	func getFileInfo(filePath: String) -> (exists: Bool, size: Int64?) {
		let fileManager = FileManager.default
		guard fileManager.fileExists(atPath: filePath) else {
			return (exists: false, size: nil)
		}
		
		let attributes = try? fileManager.attributesOfItem(atPath: filePath)
		let size = attributes?[.size] as? Int64
		return (exists: true, size: size)
	}
}
