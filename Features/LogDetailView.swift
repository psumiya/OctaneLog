import SwiftUI

struct LogDetailView: View {
    let episode: Episode
    let narrativeAgent: NarrativeAgent
    
    @State private var isRegenerating = false
    @State private var regenerateError: String?
    @State private var showFileImporter = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Map Route Path with Replay
                if !episode.route.isEmpty {
                    ReplayMapView(route: episode.route)
                        .frame(height: 300)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                
                // Transcript / Summary
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("AI FIELD LOG")
                            .font(.headline)
                            .foregroundColor(.yellow)
                        
                        Spacer()
                        
                        if isRegenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                        } else {
                            Button(action: {
                                // Trigger file picker instead of auto-running
                                showFileImporter = true
                            }) {
                                Image(systemName: "folder.badge.gearshape") // Changed icon to indicate folder
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    
                    Text(episode.summary)
                        .foregroundColor(.white.opacity(0.8))
                        .font(.body)
                    
                    if !episode.tags.isEmpty {
                        Divider().background(Color.gray)
                        HStack {
                            ForEach(episode.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(4)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    if let err = regenerateError {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationTitle(episode.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                
                // Security Scope Access (Critical for accessing outside sandbox or user selections)
                guard url.startAccessingSecurityScopedResource() else {
                    regenerateError = "Error: Permission denied to access folder."
                    return
                }
                
                Task {
                    isRegenerating = true
                    // IMPORTANT: Pass URL to agent. Agent is responsible for reading files.
                    // We must keep the security scope open while the agent works?
                    // NarrativeAgent reads the files immediately in `regenerateNarrative`.
                    let result = await narrativeAgent.regenerateNarrative(for: episode.id, manualDriveURL: url)
                    
                    // Stop accessing after work is done
                    url.stopAccessingSecurityScopedResource()
                    
                    await MainActor.run {
                        isRegenerating = false
                        if result.hasPrefix("Error:") {
                            regenerateError = result
                        } else {
                            regenerateError = nil
                        }
                    }
                }
            case .failure(let error):
                regenerateError = "Error selecting folder: \(error.localizedDescription)"
            }
        }
    }
}
