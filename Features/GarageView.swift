import SwiftUI

public struct GarageView: View {
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .leading) {
                    Text("GARAGE")
                        .font(.custom("HelveticaNeue-CondensedBlack", size: 32))
                        .foregroundColor(.white)
                        .padding()
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(0..<5) { index in
                                NavigationLink(destination: LogDetailView(index: index)) {
                                    LogRow(index: index)
                                }
                                .buttonStyle(PlainButtonStyle()) // Keeps standard row appearance
                            }
                        }
                        .padding()
                    }
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
    }
}

struct LogRow: View {
    let index: Int
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay(Image(systemName: "car.side").foregroundColor(.white))
            
            VStack(alignment: .leading) {
                Text("DRIVE LOG #00\(index + 1)")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("24 mins · 12.4 miles")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct GarageView_Previews: PreviewProvider {
    static var previews: some View {
        GarageView()
    }
}
