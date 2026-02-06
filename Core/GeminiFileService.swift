import Foundation

/// Handles interaction with the Google AI File API for uploading large media (Video).
public actor GeminiFileService {
    private let apiKey: String
    private let session: URLSession
    private let baseURL = "https://generativelanguage.googleapis.com"
    
    public init(apiKey: String) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300 // Allow long uploads
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - 1. Upload
    
    /// Uploads a file to the File API and returns the `fileUri`.
    /// Note: For files < 2GB, we can use the simple upload endpoint.
    public func uploadFile(url: URL, mimeType: String = "video/quicktime") async throws -> String {
        let fileName = url.lastPathComponent
        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        
        print("GeminiFileService: Starting upload for \(fileName) (\(fileSize) bytes)...")
        
        // 1. Initial Resumable Request
        // Docs: https://ai.google.dev/api/files
        // To keep it simple for MVP, we will use the `upload/v1beta/files` endpoint if possible, 
        // but the standard path is `POST https://generativelanguage.googleapis.com/upload/v1beta/files?key=API_KEY`
        
        // Construct the URL
        guard let uploadEndpoint = URL(string: "\(baseURL)/upload/v1beta/files?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: uploadEndpoint)
        request.httpMethod = "POST"
        
        // Headers for "Metadata-only" or "Simple upload"? 
        // We need to send the file content + metadata.
        // The simplest way for swift without multipart complexity is strict binary if supported, 
        // but the API dictates a specific protocol.
        // Let's use the standard efficient protocol: Two-step.
        
        // Step 1: Start Resumable Session
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(fileSize)", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Length")
        request.setValue("resumable", forHTTPHeaderField: "X-Goog-Upload-Protocol")
        request.setValue("start", forHTTPHeaderField: "X-Goog-Upload-Command")
        
        let metadata = ["file": ["display_name": fileName]]
        request.httpBody = try JSONSerialization.data(withJSONObject: metadata)
        
        let (_, responseHeader) = try await session.data(for: request)
        
        guard let httpResponse = responseHeader as? HTTPURLResponse,
              let uploadURLString = httpResponse.value(forHTTPHeaderField: "X-Goog-Upload-URL"),
              let uploadUrl = URL(string: uploadURLString) else {
            print("GeminiFileService: Failed to get Upload URL. Status: \((responseHeader as? HTTPURLResponse)?.statusCode ?? 0)")
            throw URLError(.badServerResponse)
        }
        
        // Step 2: Upload Bytes
        var uploadRequest = URLRequest(url: uploadUrl)
        uploadRequest.httpMethod = "POST"
        uploadRequest.setValue("\(fileSize)", forHTTPHeaderField: "Content-Length")
        uploadRequest.setValue("resumable", forHTTPHeaderField: "X-Goog-Upload-Protocol")
        uploadRequest.setValue("upload, finalize", forHTTPHeaderField: "X-Goog-Upload-Command")
        uploadRequest.setValue("0", forHTTPHeaderField: "X-Goog-Upload-Offset")
        
        // Map file data
        let fileData = try Data(contentsOf: url)
        
        let (data, response) = try await session.upload(for: uploadRequest, from: fileData)
        
        guard let finalResponse = response as? HTTPURLResponse, finalResponse.statusCode == 200 else {
            print("GeminiFileService: Upload failed. \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            throw URLError(.badServerResponse)
        }
        
        // Parse Result to get File URI
        struct FileResponse: Decodable {
            let file: FileInfo
        }
        struct FileInfo: Decodable {
             let uri: String
             let name: String
             let state: String
         }
        
        let result = try JSONDecoder().decode(FileResponse.self, from: data)
        print("GeminiFileService: Upload Complete. URI: \(result.file.uri)")
        
        return result.file.name 
    }
    
    // MARK: - 2. Poll State
    
    public func waitForActiveState(fileName: String) async throws -> String {
        // GET https://generativelanguage.googleapis.com/v1beta/files/NAME?key=KEY
        let urlString = "\(baseURL)/v1beta/\(fileName)?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        print("GeminiFileService: Polling state for \(fileName)...")
        
        var attempts = 0
        var sleepDuration: UInt64 = 1_000_000_000 // Start with 1s
        
        while attempts < 60 { // Increased to 60 attempts (up to ~2 minutes with backoff)
            let (data, _) = try await session.data(from: url)
            
            struct FileStatus: Decodable {
                let name: String
                let uri: String
                let state: String
            }
            
            if let status = try? JSONDecoder().decode(FileStatus.self, from: data) {
                print("GeminiFileService: File state: \(status.state)")
                if status.state == "ACTIVE" {
                    print("GeminiFileService: File is ACTIVE. Ready for use.")
                    return status.uri
                } else if status.state == "FAILED" {
                    print("GeminiFileService: File processing FAILED.")
                    throw URLError(.cannotParseResponse)
                }
            }
            
            try await Task.sleep(nanoseconds: sleepDuration)
            attempts += 1
            
            // Exponential backoff: 1s, 2s, 2s, 2s...
            if attempts < 3 {
                sleepDuration = min(sleepDuration * 2, 2_000_000_000)
            }
        }
        
        print("GeminiFileService: Timeout waiting for file to become ACTIVE after \(attempts) attempts.")
        throw URLError(.timedOut)
    }
    
    // MARK: - 3. Utilities
    
    public func listModels() async throws -> String {
        let urlString = "\(baseURL)/v1beta/models?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        return String(data: data, encoding: .utf8) ?? "No data"
    }

    // MARK: - 4. Generate
    // NOTE: This bypasses the GoogleGenerativeAI SDK for the generation part slightly 
    // because the SDK support for File API is simpler to just do via raw REST if we are already doing raw REST for upload.
    // BUT, we can also use the SDK if we pass the param. For consistency, let's use raw REST for now or just return the URI
    // and let the existing SDK wrapper (GeminiService.swift) use it if it supports it.
    //
    // Actually, `GoogleGenerativeAI-Swift` package handles `fileData` but maybe not `fileUri` reference directly 
    // without some construction.
    // Let's implement a simple REST generation here to be safe and dependency-free for this specific advanced feature.
    
    public func generateContent(credential: String, model: String = "gemini-1.5-flash", prompt: String, fileURIs: [String], mimeType: String = "video/quicktime") async throws -> String {
        let urlString = "\(baseURL)/v1beta/models/\(model):generateContent?key=\(credential)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Payload
        // { "contents": [{ "parts": [{ "text": "..." }, { "file_data": { "file_uri": "...", "mime_type": "video/mp4" } }] }] }
        
        var parts: [[String: Any]] = [
            ["text": prompt]
        ]
        
        for uri in fileURIs {
            parts.append([
                "file_data": [
                    "file_uri": uri,
                    "mime_type": mimeType 
                ]
            ])
        }
        
        let body: [String: Any] = [
            "contents": [
                [ "parts": parts ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
            print("GeminiFileService: Generation failed. \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            if let str = String(data: data, encoding: .utf8) { print("Response: \(str)") }
            throw URLError(.badServerResponse)
        }
        
        // Parse Response
        // structure: candidates[0].content.parts[0].text
        struct GenResponse: Decodable {
            struct Candidate: Decodable {
                struct Content: Decodable {
                    struct Part: Decodable {
                        let text: String?
                    }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]?
        }
        
        let result = try JSONDecoder().decode(GenResponse.self, from: data)
        return result.candidates?.first?.content.parts.first?.text ?? "No text returned"
    }
}
