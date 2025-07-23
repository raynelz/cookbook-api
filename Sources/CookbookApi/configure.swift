import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // Настройка окружения
    let environment = app.environment
    
    // Security headers middleware
    app.middleware.use(SecurityHeadersMiddleware())
    
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
    
    // Настройка базы данных
    let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
    let port = Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber
    let username = Environment.get("DATABASE_USERNAME") ?? "vapor_username"
    let password = Environment.get("DATABASE_PASSWORD") ?? "vapor_password"
    let database = Environment.get("DATABASE_NAME") ?? "vapor_database"
    
    // Настройка TLS для PostgreSQL
    let tlsConfig: PostgresConnection.Configuration.TLS
    if environment == .production {
        // В production используем обязательный TLS
        let tlsConfiguration = TLSConfiguration.makeClientConfiguration()
        let sslContext = try NIOSSLContext(configuration: tlsConfiguration)
        tlsConfig = .require(sslContext)
    } else {
        // В development предпочитаем TLS, но не требуем
        let tlsConfiguration = TLSConfiguration.clientDefault
        let sslContext = try NIOSSLContext(configuration: tlsConfiguration)
        tlsConfig = .prefer(sslContext)
    }
    
    // Создаем конфигурацию PostgreSQL
    let postgresConfig = SQLPostgresConfiguration(
        hostname: hostname,
        port: port,
        username: username,
        password: password,
        database: database,
        tls: tlsConfig
    )
    
    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)

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
