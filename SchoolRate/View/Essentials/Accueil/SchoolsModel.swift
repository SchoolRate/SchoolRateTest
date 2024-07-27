//
import SwiftUI
import FirebaseDatabase
import FirebaseDatabaseSwift
import Foundation

class SchoolsViewModel: ObservableObject {
    var ref = Database.database().reference()
    
    @Published var currentSchool: Lycée? = nil
    @Published var listObject = [Lycée]()
    @Published var isLoading = false
    
    init() {
        observeListObject()
    }
    
    func readValue(lycée: Lycée) {
        ref.child(String(lycée.id)).observeSingleEvent(of: .value) { snapshot in
            self.currentSchool = snapshot.value as? Lycée ?? lycée
        }
    }
    
    func observeListObject() {
        isLoading = true
        ref.observe(.value) { [weak self] parentSnapshot in
            guard let self = self else { return }
            guard let children = parentSnapshot.children.allObjects as? [DataSnapshot] else {
                self.isLoading = false
                return
            }
            self.listObject = children.compactMap({ snapshot in
                return try? snapshot.data(as: Lycée.self)
            })
            self.currentSchool = self.listObject.first
            self.isLoading = false
        }
    }
}
