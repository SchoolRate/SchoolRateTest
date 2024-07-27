import Foundation
import Firebase

@MainActor
class CommentCreationModel: ObservableObject {
    func uploadComment(generalRating: Double, teachersRating: Int, staffRating: Int, infraRating: Int, ambianceRating: Int, associationsRating: Int, materialRating: Int, dateVisit: Int64, dateOfRelease: Int64, title: String, reviewText: String, schoolID: String, responses: [Response], isEdited: Bool) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let comment = Comment(ownerUid: uid, dateOfRelease: dateOfRelease, dateOfVisit: dateVisit, ambianceRating: ambianceRating, associationsRating: associationsRating, content: reviewText, generalRating: generalRating, infraRating: infraRating, materialsRating: materialRating, staffRating: staffRating, teachersRating: teachersRating, title: title, responsesCount: 0, responses: responses, isEdited: isEdited)
        try await CommentService.uploadComment(comment, schoolID: schoolID)
    }
    
    func deleteComment(commentID: String, schoolID: String, generalRating: Double) async throws {
        try await CommentService.deleteComment(commentID: commentID, schoolID: schoolID, generalRating: generalRating)
    }
    
    func updateComment(commentID: String, newContent: String, schoolID: String) async throws {
            try await CommentService.updateComment(commentID: commentID, newContent: newContent, schoolID: schoolID)
        }
}

@MainActor
class ResponseCreationModel: ObservableObject {
    func answerToComment(responseText: String, dateOfRelease: Int64, schoolID: String, commentID: String, targetUserNickname: String? = nil, isEdited: Bool) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let response: Response
        if let targetUserNickname = targetUserNickname {
            response = Response(ownerUid: uid, dateOfResponse: dateOfRelease, responseContent: "@\(targetUserNickname) \(responseText)", isEdited: isEdited, responseCount: 0)
        } else {
            response = Response(ownerUid: uid, dateOfResponse: dateOfRelease, responseContent: responseText, isEdited: isEdited, responseCount: 0)
        }

        try await CommentService.answerToComment(response, schoolID: schoolID, commentID: commentID)
    }
    
    func deleteResponse(responseID: String, commentID: String, schoolID: String) async throws {
        try await CommentService.deleteResponse(responseID: responseID, commentID: commentID, schoolID: schoolID)
    }
}

class ResponsesFeedModel: ObservableObject, @unchecked Sendable {
    @Published private var responses: [String: [Response]] = [:]
    var schoolID: String

    init(schoolID: String) {
        self.schoolID = schoolID
    }

    func getResponses(for commentID: String) -> [Response] {
        return responses[commentID] ?? []
    }

    @MainActor
    func fetchAnswersComment(commentID: String, schoolID: String) async throws {
        let fetchedResponses = try await CommentService.fetchAnswersComment(commentID: commentID, schoolID: schoolID)
        responses[commentID] = fetchedResponses
    }
}

class CommentsFeedModel: ObservableObject, @unchecked Sendable {
    @Published var comments = [Comment]()
    var schoolID: String

    init(schoolID: String) {
        self.schoolID = schoolID
        Task { try await fetchCommentsSchool(schoolID: self.schoolID) }
    }

    @MainActor
    func fetchCommentsSchool(schoolID: String) async throws {
        self.comments = try await CommentService.fetchCommentsSchool(schoolID: schoolID)
    }
}
