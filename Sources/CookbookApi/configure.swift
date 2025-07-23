import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // Настройка окружения
    let environment = app.environment
    
    // Security headers middleware (только если файл существует)
    // app.middleware.use(SecurityHeadersMiddleware())
    
    // CORS middleware
    let allowedOrigins = Environment.get("CORS_ALLOWED_ORIGINS")?.split(separator: ",").map(String.init) ?? ["*"]
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .custom(allowedOrigins.joined(separator: ",")),
        allowedMethods: [.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
    
    // Увеличиваем максимальный размер тела запроса
    let maxFileSize = Environment.get("MAX_FILE_SIZE").flatMap(Int.init) ?? 52428800 // 50MB
    app.routes.defaultMaxBodySize = ByteCount(integerLiteral: maxFileSize)
    
    // Простая настройка базы данных БЕЗ TLS для Docker
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "db",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432,
        username: Environment.get("DATABASE_USERNAME") ?? "cookbook_user",
        password: Environment.get("DATABASE_PASSWORD") ?? "your_password_here",
        database: Environment.get("DATABASE_NAME") ?? "cookbook_production"
    ), as: .psql)

    // Миграции
    app.migrations.add(CreateRecipe())
    app.migrations.add(CreateFile())
    
    // Настройка логирования
    if environment == .development {
        app.logger.logLevel = .debug
    } else {
        app.logger.logLevel = Logger.Level(rawValue: Environment.get("LOG_LEVEL") ?? "notice") ?? .notice
    }

    // register routes
    try routes(app)
}