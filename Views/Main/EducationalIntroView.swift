import SwiftUI

/// Educational intro screen for Swift Student Challenge
/// Explains the neural network theme and learning objectives
struct EducationalIntroView: View {
    let onContinue: () -> Void
    @State private var currentPage = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private let pages: [IntroPage] = [
        IntroPage(
            title: "The Last Spark",
            description: "Experience how signals travel through neural networks in your brain",
            icon: "brain.head.profile",
            color: .cyan
        ),
        IntroPage(
            title: "Neural Pathways",
            description: "You are a spark of electricity navigating through synaptic connections. Avoid obstacles to keep the signal flowing!",
            icon: "bolt.fill",
            color: .yellow
        ),
        IntroPage(
            title: "Learn & Play",
            description: "Improve your reaction time while learning about how neurons communicate through electrical signals",
            icon: "sparkles",
            color: .purple
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.black, Color.blue.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Current page content
                VStack(spacing: 24) {
                    Image(systemName: pages[currentPage].icon)
                        .font(.system(size: 80))
                        .foregroundStyle(pages[currentPage].color)
                        .symbolEffect(.bounce, value: currentPage)
                        .accessibilityHidden(true)
                    
                    Text(pages[currentPage].title)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(pages[currentPage].description)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(pages[currentPage].title). \(pages[currentPage].description)")
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                currentPage -= 1
                            }
                            AudioHapticManager.shared.playHaptic(intensity: 0.3)
                        }) {
                            Text("Back")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .accessibilityLabel("Go back to previous page")
                    }
                    
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                currentPage += 1
                            }
                            AudioHapticManager.shared.playUITap(style: .light)
                        } else {
                            AudioHapticManager.shared.playUITap(style: .light)
                            onContinue()
                        }
                    }) {
                        Text(currentPage < pages.count - 1 ? "Next" : "Start Playing")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .accessibilityLabel(currentPage < pages.count - 1 ? "Continue to next page" : "Start playing the game")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            AudioHapticManager.shared.playUITap(style: .light)
        }
    }
}

struct IntroPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

#Preview {
    EducationalIntroView(onContinue: {})
}
