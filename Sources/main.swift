import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = Application(env)
defer { app.shutdown() }

try await configure(app)
try await app.execute()swift run App
