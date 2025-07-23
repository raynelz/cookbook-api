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
    
    private func getBaseURL() -> String {
        let scheme = Environment.get("API_SCHEME") ?? "http"
        let domain = Environment.get("API_DOMAIN") ?? "localhost:8080"
        return "\(scheme)://\(domain)"
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
        
        // Проверяем разрешенные типы файлов
        let allowedTypes = Environment.get("ALLOWED_FILE_TYPES")?.split(separator: ",").map(String.init) ?? ["image/jpeg", "image/png", "image/gif", "image/webp"]
        guard allowedTypes.contains(file.mimeType) else {
            throw Abort(.forbidden, reason: "File type not allowed")
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
        
        // Валидируем размер файла
        let maxFileSize = Environment.get("MAX_FILE_SIZE").flatMap(Int.init) ?? 52428800 // 50MB
        guard file.data.readableBytes <= maxFileSize else {
            let maxSizeMB = maxFileSize / 1024 / 1024
            throw Abort(.payloadTooLarge, reason: "File too large. Maximum size is \(maxSizeMB)MB")
        }
        
        // Определяем MIME тип
        let mimeType = file.contentType?.description ?? "application/octet-stream"
        
        // Проверяем разрешенные типы файлов
        let allowedTypes = Environment.get("ALLOWED_FILE_TYPES")?.split(separator: ",").map(String.init) ?? ["image/jpeg", "image/png", "image/gif", "image/webp"]
        guard allowedTypes.contains(mimeType) else {
            throw Abort(.badRequest, reason: "File type not allowed. Allowed types: \(allowedTypes.joined(separator: ", "))")
        }
        
        // Генерируем уникальное имя файла
        let fileExtension = file.extension ?? "jpg"
        let filename = "\(UUID().uuidString).\(fileExtension)"
        
        // Получаем данные файла
        let fileData = Data(buffer: file.data)
        
        // Создаем модель файла
        let fileModel = FileModel(
            filename: filename,
			originalName: file.filename,
            mimeType: mimeType,
            size: fileData.count,
            data: fileData
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
    
    @Sendable
    func getAllFiles(req: Request) async throws -> [FileDTO] {
        let baseURL = getBaseURL()
        return try await FileModel.query(on: req.db).all().map { file in
            var dto = file.toDTO()
            dto.url = "\(baseURL)/api/v1/files/\(file.id?.uuidString ?? "")"
            return dto
        }
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
