//

import Foundation
import SwiftUI

struct OnboardingItem: Identifiable, Equatable {
    let id = UUID()
    let image: String
    let title: String
    let content: String
}
    
final class OnboardingManager: ObservableObject {
    @Published private(set) var items: [OnboardingItem] = []
 
    func load() {
        items = [
            .init(image: "graduationcap.circle.fill", title: "Améliorez l'éducation en France", content: "Prenez part active dans l'amélioration de l'enseignement en notant vos établissements."),
            .init(image: "chart.line.downtrend.xyaxis.circle.fill", title: "Placez votre établissement sur le podium", content: "Participez tous les jours au School40, l'indice des 40 meilleurs établissements de France."),
            .init(image: "person.badge.shield.checkmark.fill", title: "Code de bienveillance de l'étudiant", content: "Ne mentez jamais et faites toujours preuve de respect et de bienveillance à l'égard du corps éducatif.")
        ]
    }
}

extension UserDefaults {
    enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
}
