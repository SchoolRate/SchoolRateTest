//

import SwiftUI

struct OnboardingInfoView: View {
    let item: OnboardingItem
    @State private var isDispatched = false
    @State private var isFirstActive = false
    @State private var count = false
    @State private var isButtonActive = false
    
    enum ImageSymbol: String {
        case firstImage = "graduationcap.circle.fill"
        case secondImage = "chart.line.downtrend.xyaxis.circle.fill"
        case thirdImage = "person.badge.shield.checkmark.fill"
        
        init(fromSymbolName symbolName: String) {
            switch symbolName {
            case ImageSymbol.firstImage.rawValue:
                self = .firstImage
            case ImageSymbol.secondImage.rawValue:
                self = .secondImage
            case ImageSymbol.thirdImage.rawValue:
                self = .thirdImage
            default:
                self = .firstImage
            }
        }
    }
    
    var imageSymbol: ImageSymbol
    
    init(item: OnboardingItem) {
        self.item = item
        self.imageSymbol = ImageSymbol(fromSymbolName: item.image)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            switch imageSymbol {
            case .firstImage:
                Image(systemName: item.image)
                    .symbolRenderingMode(.hierarchical)
                    .resizable()
                    .frame(width: 140, height: 140)
                    .symbolEffect(.pulse, options: .speed(1.5), isActive: isFirstActive)
                    .foregroundStyle(.white)
            case .secondImage:
                Image(systemName: !isDispatched ? item.image : "chart.line.uptrend.xyaxis.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .resizable()
                    .frame(width: 140, height: 140)
                    .transition(.scale)
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(.white)
            case .thirdImage:
                Image(systemName: item.image)
                    .symbolRenderingMode(.hierarchical)
                    .resizable()
                    .frame(width: 140, height: 140)
                    .symbolEffect(.bounce, value: count)
                    .foregroundStyle(.white)
            }
            Text(item.title)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 15)
            
            Text(item.content)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .font(.title3)
                .padding(.top, 5)
        }
        .onAppear {
            if !isDispatched && item.image == "chart.line.downtrend.xyaxis.circle.fill" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    self.isDispatched.toggle()
                }
            } else if !isFirstActive && item.image == "graduationcap.circle.fill" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isFirstActive.toggle()
                }
            } else if !count && item.image == "person.badge.shield.checkmark.fill" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.count.toggle()
                }
            }
        }
    }
}

#Preview {
    OnboardingInfoView(item: .init(image: "graduationcap.circle.fill", title: "Améliorez l'éducation en France", content: "Prenez part active dans l'amélioration de l'enseignement en notant vos établissements."))
}
