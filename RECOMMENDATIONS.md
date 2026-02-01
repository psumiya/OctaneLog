# Code Quality Recommendations

Based on the assessment of the OctaneLog codebase, here are prioritized recommendations to elevate the project from "Prototype" to "Production-Ready".

## 1. Architecture & Decoupling (High Priority)
### Dependency Injection in Views
**Problem**: `CockpitView` currently initializes `GeminiService` internally.
```swift
@State private var gemini = GeminiService()
```
**Recommendation**: Inject this service. This allows you to pass a `MockGeminiService` for SwiftUI Previews and UI Tests, enabling you to test the UI without making real API calls.
**Action**:
- Create a `AIService` protocol (already started).
- Update `CockpitView` to take `AIService` as an init parameter or `@EnvironmentObject`.

## 2. Maintainability
### Centralized Constants
**Problem**: String literals are scattered throughout the business logic (e.g., "The Coffee Shop", "Processing", "OCTANELOG").
**Recommendation**: Move these to a centralized `AppConstants` struct or Enum.
**Action**:
```swift
enum Narratives {
    static let processingTag = "Processing"
    static let defaultTheme = "Discovery"
}
```

### Magic Numbers
**Problem**: `NarrativeAgent.swift` contains hardcoded values like `.suffix(15)`.
**Recommendation**: define these in a Configuration struct.

## 3. Reliability & Testing
### Enhanced Test Suites
**Problem**: Test coverage is currently limited to basic unit tests.
**Recommendation**:
- **Integration Tests**: Test the full flow of `DirectorService` -> `NarrativeAgent` -> `SeasonManager`.
- **UI Tests**: Verify that the "REC" badge appears/disappears correctly.

### Structured Logging
**Problem**: Use of `print` statements in Views.
**Recommendation**: Standardize on `OSLog` or your `ThoughtLogger` for all subsystems. This allows for filtering logs by category (e.g., `com.octanelog.vision`, `com.octanelog.narrative`).

## 4. Code Style (Linting)
**Recommendation**: Stricter SwiftLint rules.
**Action**: Enable:
- `force_cast` (triggers error on `as!`)
- `force_try` (triggers error on `try!`)
- `function_body_length` (keeps functions concise)

## 5. User Experience
**Recommendation**: The "App termination" scenario.
**Action**: Your "Save First" pattern is excellent. Consider adding a Background Task (`BGTaskScheduler`) to allow the `NarrativeAgent` to finish processing if the user backgrounds the app immediately after a drive.
