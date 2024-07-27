/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An observable state object that contains profile details.
*/

import SwiftUI
import PhotosUI
import CoreTransferable
import Combine
import Firebase
import FirebaseFirestore

class ProfileModel: ObservableObject {
    @Published var users: [String: User] = [:]
    private var cancellable = Set<AnyCancellable>()
    @Published var currentUser: User?

    init() {
        fetchUsers()
        setupSubscribers()
    }
    
    private func setupSubscribers() {
        UserService.shared.$currentUser.sink { [weak self] user in
            self?.currentUser = user
            if let userId = user?.id {
                self?.fetchProfileImageUrl(userId: userId)
            }
        }.store(in: &cancellable)
    }
    
    private func fetchUsers() {
        Firestore.firestore().collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self, let snapshot = snapshot else { return }

            self.users = snapshot.documents.reduce(into: [String: User]()) { result, document in
                do {
                    let user = try document.data(as: User.self)
                    result[user.id] = user
                    
                    if let currentUserId = Auth.auth().currentUser?.uid, user.id == currentUserId {
                        self.currentUser = user
                    }
                } catch {
                    print("Error decoding user: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchProfileImageUrl(userId: String) {
        Firestore.firestore().collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self, let document = document, document.exists else {
                print("Document does not exist")
                return
            }
            
            do {
                let user = try document.data(as: User.self)
                self.currentUser?.profileImageUrl = user.profileImageUrl
                print("Profile image URL fetched: \(String(describing: user.profileImageUrl))")
            } catch {
                print("Error decoding user: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchUserProfile(userId: String) {
            Firestore.firestore().collection("users").document(userId).getDocument { document, error in
                if let document = document, document.exists {
                    do {
                        self.currentUser = try document.data(as: User.self)
                    } catch {
                        print("Error decoding user: \(error.localizedDescription)")
                    }
                } else {
                    print("Document does not exist")
                }
            }
        }
}
