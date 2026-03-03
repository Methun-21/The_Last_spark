import SwiftUI

struct LicensesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Licenses & Attributions")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.bottom, 10)
                
                Group {
                    licenseSection(title: "Game Engine & Logic", content: "Built with pure SwiftUI and custom physics logic.")
                    
                    licenseSection(title: "Audio System", content: "Powered by AVFoundation and CoreHaptics.\nSound effects: Custom & Standard iOS System Sounds.")
                    
                    licenseSection(title: "Fonts", content: "San Francisco (System Font) by Apple Inc.")
                    
                    licenseSection(title: "Design Assets", content: "SF Symbols by Apple Inc.\nProcedural Graphics generated via SwiftUI Shapes.")
                }
                
                Spacer()
            }
            .padding(24)
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    func licenseSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.cyan)
            
            Text(content)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            
            Divider().background(Color.white.opacity(0.1))
        }
    }
}
