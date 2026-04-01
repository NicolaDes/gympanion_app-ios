// GympanionApp/data/remote/ApiService.swift
import Foundation

protocol ApiServiceProtocol {
    func fetchExercises() async throws -> [ExerciseDto]
    func fetchWorkouts() async throws -> [WorkoutDto]
    func fetchSessions() async throws -> [SessionDto]
    func login(email: String, password: String) async throws -> String   // returns JWT
    func register(email: String, password: String, displayName: String) async throws -> String
}

final class ApiService: ApiServiceProtocol {
    private let baseURL: URL
    private let interceptor: AuthInterceptor
    private let session: URLSession

    private lazy var decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private lazy var encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    init(baseURL: URL = URL(string: "https://api.gympanion.com/v1")!,
         session: URLSession = .shared,
         interceptor: AuthInterceptor = AuthInterceptor()) {
        self.baseURL = baseURL
        self.session = session
        self.interceptor = interceptor
    }

    func fetchExercises() async throws -> [ExerciseDto] {
        try await get("exercises")
    }

    func fetchWorkouts() async throws -> [WorkoutDto] {
        try await get("workouts")
    }

    func fetchSessions() async throws -> [SessionDto] {
        try await get("sessions")
    }

    func login(email: String, password: String) async throws -> String {
        struct Body: Encodable { let email: String; let password: String }
        struct Response: Decodable { let token: String }
        let response: Response = try await post("auth/login", body: Body(email: email, password: password))
        return response.token
    }

    func register(email: String, password: String, displayName: String) async throws -> String {
        struct Body: Encodable { let email: String; let password: String; let displayName: String }
        struct Response: Decodable { let token: String }
        let response: Response = try await post("auth/register", body: Body(email: email, password: password, displayName: displayName))
        return response.token
    }

    // MARK: - Helpers

    private func get<T: Decodable>(_ path: String) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "GET"
        request = interceptor.apply(to: request)
        let (data, response) = try await session.data(for: request)
        try validate(response)
        return try decoder.decode(T.self, from: data)
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        request = interceptor.apply(to: request)
        let (data, response) = try await session.data(for: request)
        try validate(response)
        return try decoder.decode(T.self, from: data)
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw URLError(.init(rawValue: code))
        }
    }
}
