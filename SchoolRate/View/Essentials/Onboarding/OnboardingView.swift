//

import SwiftUI

let gradientColors: [Color] = [
    .gradientTop,
    .gradientBottom
]

struct OnboardingView: View {
    @StateObject private var manager = OnboardingManager()
    @State private var showBtn = false
    @State private var isOscillating = false
    
    var body: some View {
        ZStack {
            if !manager.items.isEmpty {
                TabView {
                    ForEach(manager.items) { item in
                        OnboardingInfoView(item: item)
                            .onAppear {
                                if item == manager.items.last {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        withAnimation(.spring().delay(0.25)) {
                                            showBtn.toggle()
                                        }
                                    }
                                }
                            }
                            .overlay(alignment: .bottom) {
                                if showBtn {
                                    Button("Compris", systemImage: "arrow.right") {
                                        UserDefaults.standard.set(true, forKey: UserDefaults.Keys.hasCompletedOnboarding)
                                    }
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .frame(width: 150, height: 50)
                                    .foregroundStyle(.white)
                                    .background {
                                        Capsule().strokeBorder(Color.white, lineWidth: 1.5)
                                    }
                                    .opacity(isOscillating ? 1 : 0.2)
                                    .offset(y: 80)
                                    .onAppear {
                                        withAnimation(Animation.easeInOut(duration: 1.2).repeatForever()) {
                                            self.isOscillating.toggle()
                                        }
                                    }
                                }
                            }
                    }
                }
                .background(Gradient(colors: gradientColors))
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
        .onAppear(perform: manager.load)
    }
}

#Preview {
    OnboardingView()
}
