import Fluent
import Vapor

struct FileController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let files = routes.grouped("files")
        
        files.get(":fileID", use: self.getFile)
        files.post("upload", use: self.uploadFile)
        files.get(use: self.getAllFiles)
        files.delete(":fileID", use: self.deleteFile)
    }
    
    @Sendable
    func getFile(req: Request) async throws -> Response {
        guard let fileID = req.parameters.get("fileID"),
              let uuid = UUID(uuidString: fileID) else {
            throw Abort(.badRequest, reason: "Invalid file ID")
        }
        
        guard let file = try await FileModel.find(uuid, on: req.db) else {
            throw Abort(.notFound, reason: "File not found")
        }
        
        // Создаем Response с данными файла
        let response = Response()
        response.body = .init(data: file.data)
        
        // Устанавливаем правильный Content-Type
        let mimeTypeParts = file.mimeType.split(separator: "/")
        if mimeTypeParts.count == 2 {
            let type = String(mimeTypeParts[0])
            let subType = String(mimeTypeParts[1])
            response.headers.contentType = HTTPMediaType(type: type, subType: subType)
        } else {
            response.headers.contentType = .binary
        }
        
        // Убираем дублирующий Content-Length - Vapor добавит автоматически
        response.headers.add(name: .contentDisposition, value: "inline; filename=\"\(file.originalName)\"")
        
        return response
    }
    
    @Sendable
    func uploadFile(req: Request) async throws -> FileUploadResponse {
        // Декодируем multipart form data
        let data = try req.content.decode([String: File].self)
        
        guard let file = data["file"] else {
            throw Abort(.badRequest, reason: "No file field found in request")
        }
        
        // Валидируем размер файла (максимум 20MB для изображений)
        guard file.data.readableBytes <= 20 * 1024 * 1024 else {
            throw Abort(.payloadTooLarge, reason: "File too large. Maximum size is 20MB")
        }
        
        // Определяем MIME тип
        let mimeType = file.contentType?.description ?? "application/octet-stream"
        
        // Валидируем тип файла (только изображения)
        guard mimeType.hasPrefix("image/") else {
            throw Abort(.badRequest, reason: "Only image files are allowed")
        }
        
        // Генерируем уникальное имя файла
        let fileExtension = file.extension ?? "jpg"
        let filename = "\(UUID().uuidString).\(fileExtension)"
        
        // Получаем данные файла
        let fileData = Data(buffer: file.data)
        
        // Создаем модель файла
        let fileModel = FileModel(
            filename: filename,
            originalName: file.filename ?? "unknown",
            mimeType: mimeType,
            size: fileData.count,
            data: fileData
        )
        
        // Сохраняем в базу данных
        try await fileModel.save(on: req.db)
        
        return FileUploadResponse(
            id: fileModel.id!,
            filename: fileModel.filename,
            originalName: fileModel.originalName,
            size: fileModel.size,
            url: "/api/v1/files/\(fileModel.id!.uuidString)"
        )
    }
    
    @Sendable
    func getAllFiles(req: Request) async throws -> [FileDTO] {
        try await FileModel.query(on: req.db).all().map { $0.toDTO() }
    }
    
    @Sendable
    func deleteFile(req: Request) async throws -> HTTPStatus {
        guard let fileID = req.parameters.get("fileID"),
              let uuid = UUID(uuidString: fileID) else {
            throw Abort(.badRequest, reason: "Invalid file ID")
        }
        
        guard let file = try await FileModel.find(uuid, on: req.db) else {
            throw Abort(.notFound, reason: "File not found")
        }

        try await file.delete(on: req.db)
        return .noContent
    }
}
