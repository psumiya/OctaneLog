import Foundation
import OctaneLogCore

print("🎬 Starting Marathon Agent Sim: 'The Showrunner'...")

let agent = NarrativeAgent()

print("\n--- Episode 1: The Setup ---")
let ep1Events = [
    "User drove 45 miles on PCH.",
    "Stopped at a Coffee Shop in Malibu.",
    "Saw a classic 1969 Mustang."
]
let ep1Result = await agent.processDrive(events: ep1Events, route: [])
print(">> Generated: \(ep1Result)")

print("\n--- Episode 2: The Callback ---")
// This episode should trigger the agent to recall the "Coffee Shop" from Episode 1
let ep2Events = [
    "User drove 10 miles to the same Coffee Shop.",
    "Weather was rainy.",
    "Traffic was heavy."
]
let ep2Result = await agent.processDrive(events: ep2Events, route: [])
print(">> Generated: \(ep2Result)")

print("\n✅ Simulation Complete. Check logs for <thought> signatures.")

// Run Periodic Recap Verification
await RecapVerifier.verifyRecaps()

// Run OctaneSoul Verification
await OctaneSoulVerifier.verify()
