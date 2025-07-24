import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) async throws {

	// MARK: - Environment Settings

	let allowedOrigins = Environment.get("CORS_ALLOWED_ORIGINS")?.split(separator: ",").map(String.init) ?? ["*"]

	// MARK: - CORS Settings

	let corsConfiguration = CORSMiddleware.Configuration(
		allowedOrigin: .any(allowedOrigins),
		allowedMethods: [.GET, .POST, .PATCH, .DELETE, .OPTIONS],
		allowedHeaders: [
			.accept,
			.authorization,
			.contentType,
			.origin,
			.xRequestedWith,
			.userAgent,
			.accessControlAllowOrigin
		]
	)

	app.middleware.use(CORSMiddleware(configuration: corsConfiguration))

	// MARK: - Max File Size Limit

	let maxFileSize = Environment.get("MAX_FILE_SIZE").flatMap(Int.init) ?? 52428800 // 50MB
	app.routes.defaultMaxBodySize = ByteCount(integerLiteral: maxFileSize)

	// MARK: - Database Configuration

	app.databases.use(
		.postgres(
			configuration: .init(
				hostname: Environment.get("DATABASE_HOST") ?? "db",
				username: Environment.get("DATABASE_USERNAME") ?? "cookbook_user",
				password: Environment.get("DATABASE_PASSWORD") ?? "password",
				database: Environment.get("DATABASE_NAME") ?? "cookbook_production",
				tls: .disable
			)
		),
		as: .psql
	)

	// MARK: - Migrations Registration

	app.logger.info("📋 Registering migrations...")

	app.migrations.add(CreateRecipe())
	app.migrations.add(CreateFile())

	try await app.autoMigrate()

	// MARK: - Logger Level Setup

	switch app.environment {
	case .development:
		app.logger.logLevel = .debug
	default:
		app.logger.logLevel = Logger.Level(rawValue: Environment.get("LOG_LEVEL") ?? "notice") ?? .notice
	}

	// MARK: - Routes Registration

	try routes(app)
}
