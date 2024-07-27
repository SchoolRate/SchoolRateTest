//

import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    var bio: String?
    var username: String
    var email: String
    var votesCount: Int?
    var profileImageUrl: String?
    var prefersNotifications = true
}
