import Foundation
import Firebase
import FirebaseFirestoreSwift

struct CommentService {
    static func uploadComment(_ comment: Comment, schoolID: String) async throws {
        let commentData = try Firestore.Encoder().encode(comment)
        
        try await Firestore.firestore().collection("comments").addDocument(data: commentData)
        
        let schoolRef = Database.database().reference().child(schoolID)
        
        try await schoolRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var value = currentData.value as? [String: AnyObject] ?? [:]
            var reviewCount = value["reviewCount"] as? Int ?? 0
            reviewCount += 1
            value["reviewCount"] = reviewCount as AnyObject?
            
            var vote = value["vote"] as? Double ?? 1.0
            vote = (vote * Double(reviewCount - 1) + comment.generalRating) / Double(reviewCount)
            value["vote"] = vote as AnyObject?
            
            var oneStarCount = value["oneStarCount"] as? Int ?? 0
            var twoStarCount = value["twoStarCount"] as? Int ?? 0
            var threeStarCount = value["threeStarCount"] as? Int ?? 0
            var fourStarCount = value["fourStarCount"] as? Int ?? 0
            var fiveStarCount = value["fiveStarCount"] as? Int ?? 0
            
            switch Int(comment.generalRating) {
            case 1:
                oneStarCount += 1
            case 2:
                twoStarCount += 1
            case 3:
                threeStarCount += 1
            case 4:
                fourStarCount += 1
            case 5:
                fiveStarCount += 1
            default:
                break
            }
            
            value["oneStarCount"] = oneStarCount as AnyObject?
            value["twoStarCount"] = twoStarCount as AnyObject?
            value["threeStarCount"] = threeStarCount as AnyObject?
            value["fourStarCount"] = fourStarCount as AnyObject?
            value["fiveStarCount"] = fiveStarCount as AnyObject?
            
            currentData.value = value
            
            print("Updated star counts inside transaction: 1-star: \(oneStarCount), 2-star: \(twoStarCount), 3-star: \(threeStarCount), 4-star: \(fourStarCount), 5-star: \(fiveStarCount)")
            
            return TransactionResult.success(withValue: currentData)
        })
        
        try await schoolRef.child("comments").child(comment.id).setValue(commentData)
    }
    
    static func deleteComment(commentID: String, schoolID: String, generalRating: Double) async throws {
            let commentRef = Firestore.firestore().collection("comments").document(commentID)
            try await commentRef.delete()
            
            let schoolRef = Database.database().reference().child(schoolID)
            
            try await schoolRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                var value = currentData.value as? [String: AnyObject] ?? [:]
                var reviewCount = value["reviewCount"] as? Int ?? 0
                reviewCount -= 1
                value["reviewCount"] = reviewCount as AnyObject?
                
                if reviewCount > 0 {
                    var vote = value["vote"] as? Double ?? 1.0
                    vote = (vote * Double(reviewCount + 1) - generalRating) / Double(reviewCount)
                    value["vote"] = vote as AnyObject?
                } else {
                    value["vote"] = 1.0 as AnyObject?
                }
                
                var oneStarCount = value["oneStarCount"] as? Int ?? 0
                var twoStarCount = value["twoStarCount"] as? Int ?? 0
                var threeStarCount = value["threeStarCount"] as? Int ?? 0
                var fourStarCount = value["fourStarCount"] as? Int ?? 0
                var fiveStarCount = value["fiveStarCount"] as? Int ?? 0
                
                switch Int(generalRating) {
                case 1:
                    oneStarCount -= 1
                    value["oneStarCount"] = oneStarCount as AnyObject?
                case 2:
                    twoStarCount -= 1
                    value["twoStarCount"] = twoStarCount as AnyObject?
                case 3:
                    threeStarCount -= 1
                    value["threeStarCount"] = threeStarCount as AnyObject?
                case 4:
                    fourStarCount -= 1
                    value["fourStarCount"] = fourStarCount as AnyObject?
                case 5:
                    fiveStarCount -= 1
                    value["fiveStarCount"] = fiveStarCount as AnyObject?
                default:
                    break
                }
                
                currentData.value = value
                return TransactionResult.success(withValue: currentData)
            })
            
            let commentDataRef = schoolRef.child("comments").child(commentID)
            try await commentDataRef.removeValue()
        }

    static func deleteResponse(responseID: String, commentID: String, schoolID: String) async throws {
        let responseRef = Firestore.firestore().collection("comments").document(commentID).collection("responses").document(responseID)
        try await responseRef.delete()
        
        let commentRef = Database.database().reference().child(schoolID).child("comments").child(commentID)
        
        try await commentRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var value = currentData.value as? [String: AnyObject] ?? [:]
            var responseCount = value["responsesCount"] as? Int ?? 0
            responseCount -= 1
            value["responsesCount"] = responseCount as AnyObject?
            
            currentData.value = value
            return TransactionResult.success(withValue: currentData)
        })
        
        let responseDataRef = commentRef.child("responses").child(responseID)
        try await responseDataRef.removeValue()
    }
    
    static func fetchAnswersComment(commentID: String, schoolID: String) async throws -> [Response] {
        let schoolRef = Database.database().reference().child(schoolID).child("comments").child(commentID).child("responses")
        return try await withCheckedThrowingContinuation { continuation in
            schoolRef.observeSingleEvent(of: .value, with: { snapshot in
                guard snapshot.exists() else {
                    continuation.resume(returning: [])
                    return
                }
                
                var responses: [Response] = []
                if let children = snapshot.children.allObjects as? [DataSnapshot] {
                    for child in children {
                        if let response = Response(snapshot: child) {
                            responses.append(response)
                        }
                    }
                }
                print("Fetched \(responses.count) responses for comment \(commentID)")  // Debug print statement
                continuation.resume(returning: responses)
            }) { error in
                continuation.resume(throwing: error)
            }
        }
    }

    static func fetchCommentsSchool(schoolID: String) async throws -> [Comment] {
            let schoolRef = Database.database().reference().child(schoolID).child("comments")
            return try await withCheckedThrowingContinuation { continuation in
                schoolRef.observeSingleEvent(of: .value, with: { snapshot in
                    var comments: [Comment] = []
                    if let children = snapshot.children.allObjects as? [DataSnapshot] {
                        for child in children {
                            if let comment = Comment(snapshot: child) {
                                comments.append(comment)
                            }
                        }
                    }
                    continuation.resume(returning: comments)
                }) { error in
                    continuation.resume(throwing: error)
                }
            }
        }
    
    static func updateComment(commentID: String, newContent: String, schoolID: String) async throws {
            let commentRef = Database.database().reference().child(schoolID).child("comments").child(commentID)
            
            try await commentRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                var value = currentData.value as? [String: Any] ?? [:]
                value["content"] = newContent
                value["isEdited"] = true
                currentData.value = value
                return TransactionResult.success(withValue: currentData)
            })
        }
    
    static func answerToComment(_ response: Response, schoolID: String, commentID: String) async throws {
        let responseData = try Firestore.Encoder().encode(response)
        
        try await Firestore.firestore().collection("comments").document(commentID).collection("responses").addDocument(data: responseData)
        
        let commentRef = Database.database().reference().child(schoolID).child("comments").child(commentID)
        
        try await commentRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            var value = currentData.value as? [String: AnyObject] ?? [:]
            var responseCount = value["responsesCount"] as? Int ?? 0
            responseCount += 1
            value["responsesCount"] = responseCount as AnyObject?
            
            currentData.value = value
            return TransactionResult.success(withValue: currentData)
        })
        
        try await commentRef.child("responses").child(response.id).setValue(responseData)
    }
}
