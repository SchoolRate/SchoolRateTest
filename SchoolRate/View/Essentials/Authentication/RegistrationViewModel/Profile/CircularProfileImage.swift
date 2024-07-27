//

import SwiftUI
import Kingfisher
import FirebaseFirestore
import Firebase

struct CircularProfileImage: View {
    let userId: String
    
    @State private var imageUrl: String? = nil
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
        Group {
            if let imageUrl = imageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .frame(width: 70, height: 60)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .font(.system(size: 62))
                    .onAppear {
                        fetchProfileImageUrl()
                    }
            }
        }
    }
    
    private func fetchProfileImageUrl() {
        Firestore.firestore().collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let user = try document.data(as: User.self)
                    self.imageUrl = user.profileImageUrl
                    print("Profile image URL fetched: \(String(describing: user.profileImageUrl))")
                } catch {
                    print("Error decoding user: \(error.localizedDescription)")
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}

#Preview {
    CircularProfileImage(userId: "kV0VnefQh2StZS6e8jf53U7g27m1")
}
