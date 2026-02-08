import SwiftUI

public struct SettingsView: View {
    @State private var apiKey: String = ""
    @AppStorage("user_gemini_api_key") private var storedKey: String = ""
    @AppStorage("isDeveloperMode") private var isDeveloperMode: Bool = false
    @AppStorage(AppConstants.Settings.uploadOverWifiOnly) private var uploadOverWifiOnly: Bool = true
    @AppStorage(AppConstants.Settings.videoQuality) private var videoQuality: String = "480p"
    @State private var isKeyVisible = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Gemini Configuration")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.headline)
                        
                        HStack {
                            if isKeyVisible {
                                TextField("Enter AIzaSy...", text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            } else {
                                SecureField("Enter AIzaSy...", text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            Button(action: {
                                isKeyVisible.toggle()
                            }) {
                                Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text("Your key is stored locally on this device.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                    
                    if !storedKey.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Key Configured")
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Key Missing")
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        saveKey()
                    }) {
                        Text("Save Key")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.bold)
                    }
                    .disabled(apiKey.isEmpty)
                    
                    if !storedKey.isEmpty {
                        Button(action: {
                            clearKey()
                        }) {
                            Text("Clear Key")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Video Configuration")) {
                    Toggle("Upload over WiFi Only", isOn: $uploadOverWifiOnly)
                    
                    Picker("Video Quality", selection: $videoQuality) {
                        Text("480p (Data Saver)").tag("480p")
                        Text("720p (Standard)").tag("720p")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text("Higher quality usage more data and storage.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Developer Options")) {
                    Toggle("Developer Mode", isOn: $isDeveloperMode)
                }
                
                Section(header: Text("About")) {
                    NavigationLink(destination: ScrollView {
                        Text(LegalText.disclaimer)
                            .padding()
                    }.navigationTitle("Safety & Legal")) {
                        Text("Safety & Legal Disclaimer")
                    }
                    
                    Link("Get a Gemini API Key", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                    Text("Version 1.0.0")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                self.apiKey = storedKey
            }
        }
    }
    
    private func saveKey() {
        storedKey = apiKey
        // Force GeminiService to reload (if it was observing, but for now a restart might be needed or simple re-check)
    }
    
    private func clearKey() {
        storedKey = ""
        apiKey = ""
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
