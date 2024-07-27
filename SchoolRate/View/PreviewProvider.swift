//

import SwiftUI
import Firebase

extension PreviewProvider {
    static var dev: DeveloperPreview {
        return DeveloperPreview.shared
    }
}

final class DeveloperPreview: Sendable {
    static let shared = DeveloperPreview()
    
    let user = User(id: NSUUID().uuidString, username: "kwiky", email: "ye")
}
