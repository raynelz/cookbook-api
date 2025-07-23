import Vapor

struct SecurityHeadersMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        
        // Security headers
        response.headers.add(name: "X-Content-Type-Options", value: "nosniff")
        response.headers.add(name: "X-Frame-Options", value: "DENY")
        response.headers.add(name: "X-XSS-Protection", value: "1; mode=block")
        response.headers.add(name: "Referrer-Policy", value: "strict-origin-when-cross-origin")
        response.headers.add(name: "Content-Security-Policy", value: "default-src 'self'")
        
        // HTTPS только в production
        if request.application.environment == .production {
            response.headers.add(name: "Strict-Transport-Security", value: "max-age=31536000; includeSubDomains")
        }
        
        return response
    }
}