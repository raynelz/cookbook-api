import Fluent
import Vapor

struct FileController: RouteCollection {

	func boot(routes: any RoutesBuilder) throws {
		let files = routes.grouped("files")

		files.get(":fileID", use: getFile)
		files.get(use: getAllFiles)
		files.post("upload", use: uploadFile)
		files.delete(":fileID", use: deleteFile)
	}

	private func getBaseURL() -> String {
		let scheme = Environment.get("API_SCHEME") ?? "http"
		let domain = Environment.get("API_DOMAIN") ?? "localhost:8080"
		return "\(scheme)://\(domain)"
	}

	func getFile(req: Request) async throws -> Response {
		guard let fileID = req.parameters.get("fileID"),
			  let uuid = UUID(uuidString: fileID) else {
			throw Abort(.badRequest, reason: "Invalid file ID")
		}

		guard let file = try await FileModel.find(uuid, on: req.db) else {
			throw Abort(.notFound, reason: "File not found")
		}

		// Проверяем существование файла на диске
		let fileService = FileService()
		let fileInfo = fileService.getFileInfo(filePath: file.filePath)
		
		guard fileInfo.exists else {
			throw Abort(.notFound, reason: "File not found on disk")
		}

		// Читаем файл с диска
		let fileData = try fileService.getFileData(filePath: file.filePath)

		// Создаем Response с данными файла
		let response = Response()
		response.body = .init(data: fileData)

		// Устанавливаем правильный Content-Type
		let mimeTypeParts = file.mimeType.split(separator: "/")
		if mimeTypeParts.count == 2 {
			let type = String(mimeTypeParts[0])
			let subType = String(mimeTypeParts[1])
			response.headers.contentType = HTTPMediaType(type: type, subType: subType)
		} else {
			response.headers.contentType = .binary
		}

		response.headers.add(name: .contentDisposition, value: "inline; filename=\"\(file.originalName)\"")
		
		// Добавляем кэширование для изображений
		if file.mimeType.hasPrefix("image/") {
			response.headers.add(name: .cacheControl, value: "public, max-age=86400") // 24 часа
		}

		return response
	}

	func uploadFile(req: Request) async throws -> FileUploadResponse {
		// Декодируем multipart form data
		let data = try req.content.decode([String: File].self)

		guard let file = data["file"] else {
			throw Abort(.badRequest, reason: "No file field found in request")
		}

		// Сохраняем файл на диск через FileService
		let fileService = FileService()
		let (filename, filePath) = try fileService.saveFile(file)

		// Определяем MIME тип
		let mimeType = file.contentType?.description ?? "application/octet-stream"

		// Создаем модель файла
		let fileModel = FileModel(
			filename: filename,
			originalName: file.filename,
			mimeType: mimeType,
			size: file.data.readableBytes,
			filePath: filePath
		)

		// Сохраняем в базу данных
		try await fileModel.save(on: req.db)

		let baseURL = getBaseURL()

		return FileUploadResponse(
			id: fileModel.id!,
			filename: fileModel.filename,
			originalName: fileModel.originalName,
			size: fileModel.size,
			url: "\(baseURL)/api/v1/files/\(fileModel.id!.uuidString)"
		)
	}

	func getAllFiles(req: Request) async throws -> [FileDTO] {
		let baseURL = getBaseURL()
		return try await FileModel.query(on: req.db).all().map { file in
			var dto = file.toDTO()
			dto.url = "\(baseURL)/api/v1/files/\(file.id?.uuidString ?? "")"
			return dto
		}
	}

	func deleteFile(req: Request) async throws -> HTTPStatus {
		guard let fileID = req.parameters.get("fileID"),
			  let uuid = UUID(uuidString: fileID) else {
			throw Abort(.badRequest, reason: "Invalid file ID")
		}

		guard let file = try await FileModel.find(uuid, on: req.db) else {
			throw Abort(.notFound, reason: "File not found")
		}

		// Удаляем файл с диска
		let fileService = FileService()
		try fileService.deleteFile(filePath: file.filePath)

		// Удаляем запись из базы данных
		try await file.delete(on: req.db)
		return .noContent
	}
}
