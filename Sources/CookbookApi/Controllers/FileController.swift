import Fluent
import Vapor

struct FileController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let files = routes.grouped("files")
        
        files.get(":fileID", use: self.getFile)
        files.post("upload", use: self.uploadFile)
    }
    
    @Sendable
    func getFile(req: Request) async throws -> Response {
        guard let fileID = req.parameters.get("fileID") else {
            throw Abort(.badRequest)
        }
        
        // Путь к папке uploads
        let uploadsPath = req.application.directory.workingDirectory + "uploads/"
        let filePath = uploadsPath + fileID
        
        // Проверяем существует ли файл
        let fileExists = FileManager.default.fileExists(atPath: filePath)
        guard fileExists else {
            throw Abort(.notFound)
        }
        
        // Возвращаем файл
        return req.fileio.streamFile(at: filePath)
    }
    
    @Sendable
    func uploadFile(req: Request) async throws -> [String: String] {
        let file = try req.content.decode(File.self)
        
        // Создаем папку uploads если её нет
        let uploadsPath = req.application.directory.workingDirectory + "uploads/"
        try FileManager.default.createDirectory(atPath: uploadsPath, withIntermediateDirectories: true)
        
        // Генерируем уникальное имя файла
        let fileName = UUID().uuidString + "." + (file.extension ?? "jpg")
        let filePath = uploadsPath + fileName
        
        // Сохраняем файл
        try await req.fileio.writeFile(file.data, at: filePath)
        
        return ["fileId": fileName, "url": "/files/\(fileName)"]
    }
}