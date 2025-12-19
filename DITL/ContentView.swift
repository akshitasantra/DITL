import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack{
            ZStack {
                Color(red: 0.98, green: 0.92, blue: 0.95)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Today")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color(red: 0.55, green: 0.3, blue: 0.45))
                        
                        Spacer()
                        
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.55, green: 0.3, blue: 0.45))
                            .padding(10)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    Text(formattedDate())
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.65, green: 0.45, blue: 0.55))
                    
                    Spacer()
                }
                .padding()
            }
        }
    }

    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
}

#Preview {
    ContentView()
}
