# OctaneLog

> "Mundane to Octane."
> >
> Converting seconds of mundane life into a grand narrative.

## Vision
**OctaneLog** is an iOS application that uses on-device Vision AI and Gemini 3 to capture, analyze, and narrate your life on the road.

- **The Director**: Continuously records your drive and uses Apple's Vision framework to analyze scenery, lighting, and objects in real-time.
- **The Editor (Gemini 3)**: Combines video footage with local Vision analysis to generate vivid narrative summaries of your drives.
- **Smart Processing**: Intelligently uploads driving footage to Gemini when local Vision analysis detects significant events or scenery, ensuring high-quality narration.

## Architecture
- **Perception Domain**: Hardware-abstracted Camera logic (`VideoSourceProtocol`) & Real-time AI analysis.
- **Narrative Domain**: Generative text synthesis and data persistence (`SeasonManager`).

## Privacy & Data Safety

OctaneLog is designed to be **Privacy Aware**.

- **Bring Your Own Key (BYOK)**: *Default Configuration*. Currently, you use your own Google Gemini API Key. Your data is processed under your personal or enterprise agreement with Google.
- **Smart Redaction**: The "Director" agent is explicitly prompted to **ignore** license plates, faces, and specific street numbers, focusing strictly on vehicle types, scenery, and driving dynamics.
- **Local Narrative & Data**: Location coordinates are sent to Gemini *only* for context (e.g., to identify "Golden Gate Bridge" vs "A Red Bridge"). The raw GPS history (Route) and the generated text stories (the "Saga") are saved locally on your device. You own your data.
- **Background Autonomy**: The app requires "Always" location permission to autonomously detect and log drives even when the phone is locked. This telemetry is processed locally to determine drive state (Stationary vs Cruising) and is never uploaded to a cloud server.


## Directory Structure
- `App/`: Main App Entry point.
- `Domains/`: Core Logic separated by Domain (Perception, Narrative).
- `Features/`: SwiftUI Views and Feature logic.
- `Core/`: Shared Utilities.

## Getting Started

> ⚠️ **This project is under active development. Builds may fail. Tests may fail. Please use with caution.**

### Prerequisites
- Xcode 15+
- Swift 5.9+
- Gemini API Key

### Setup
1. Open `Package.swift` in Xcode.
2. Configure `GEMINI_API_KEY` in `GeminiService.swift` or environment.
3. Run `swift build` or build the `OctaneLogCore` scheme in Xcode.

## How to Test and Run

### Option 1: Quick Verification (CLI)
If you don't want to open Xcode, you can confirm the code works by running the unit tests:
```bash
swift test
```

### Option 2: Visual Preview (Xcode)
1. Open the folder in Xcode:
   ```bash
   open Package.swift
   ```
2. In the Project Navigator (left sidebar), go to `Features` -> `CockpitView.swift`.
3. The **Canvas** (preview pane) should appear on the right. If not, press `Option + Command + Enter`.
4. You will see the "Heads-Up Display" UI in the preview.

### Option 3: Run on Device (Detailed)
### Run on Simulator or Device
Since `OctaneLog` is a Swift Package Logic Library, we include a "Host App" called `OctaneRunner` to run it visually.

1.  **Open Project**:
    -   Navigate to `OctaneRunner/` folder.
    -   Open `OctaneRunner.xcodeproj`.

2.  **Run**:
    -   Select your physical device or a simulator.
    -   Hit Play (Command + R).
    -   Xcode will automatically handle the signing (ensure a Team is selected in the project settings if prompted).

> **Note**: This is a video-only application. Audio recording is not implemented and microphone access is not requested.

### Troubleshooting

**"Untrusted Developer" Error**:
1. Open **Settings** on your iPhone.
2. Go to **General** -> **VPN & Device Management**.
3. Under "Developer App", tap your email/Apple ID.
4. Tap **Trust**.

**"Developer Mode Required" Error**:
1. Open **Settings** -> **Privacy & Security**.
2. Scroll to **Developer Mode** and enable it.
3. Restart your iPhone.

## ⚖️ Safety & Legal Disclaimer

**By using this software, you agree to the following terms:**

1.  **Distracted Driving**: **Do not interact with this application while driving.** You must always prioritize the safe operation of your vehicle over any interaction with this app. OctaneLog is designed to run autonomously. Any manual interaction (starting/stopping drives, viewing logs) must be done only when the vehicle is stationary and parked in a safe location.
2.  **Liability**: The developer of OctaneLog is not liable for any accidents, injuries, or damages resulting from the use of this application. You assume full risk and responsibility for your driving and the use of this software.
3.  **Privacy & Compliance**: This application records video of public roads. You are solely responsible for complying with all local, state, and federal laws regarding video recording and privacy. Do not use this application in jurisdictions where dashcam recording is prohibited.
4.  **Data Usage**: Video analysis is performed on-device. Data is uploaded to third-party AI services (Google Gemini) only if you explicitly configure it with your API key. You are responsible for the data you process and share.

**Drive Safe. Eyes on the Road.**

