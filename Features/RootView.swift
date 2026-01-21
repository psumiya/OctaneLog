import SwiftUI

public struct RootView: View {
    @State var director: DirectorService
    
    public init(director: DirectorService) {
        self.director = director
    }
    
    public var body: some View {
        TabView {
            CockpitView(director: director)
                .tabItem {
                    Label("Cockpit", systemImage: "video.circle.fill")
                }
            
            GarageView()
                .tabItem {
                    Label("Garage", systemImage: "car.fill")
                }
        }
        .accentColor(.red) // Branding color
        .preferredColorScheme(.dark)
    }
}
