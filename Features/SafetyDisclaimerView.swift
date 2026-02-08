import SwiftUI

public struct SafetyDisclaimerView: View {
    @Binding var hasAccepted: Bool
    
    public init(hasAccepted: Binding<Bool>) {
        self._hasAccepted = hasAccepted
    }
    
    public var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                
                Text("Safety First")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                
                
                VStack(spacing: 20) {
                    ScrollView {
                        Text(LegalText.disclaimer)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .frame(maxHeight: .infinity)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        hasAccepted = true
                        UserDefaults.standard.set(true, forKey: "hasAcceptedSafetyDisclaimer")
                    }
                }) {
                    Text("I Agree & Understand")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}


