/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A representation of a single landmark.
*/

import Foundation
import SwiftUI
import CoreLocation
import FirebaseFirestoreSwift
import Firebase

struct Lycée: Hashable, Codable, Identifiable {
    var id: Int
    var name: String
    var adresse: String
    var vote: Double
    var description: String
    var city: String
    var category: String
    var reviewCount: Int?
    var oneStarCount: Int?
    var twoStarCount: Int?
    var threeStarCount: Int?
    var fourStarCount: Int?
    var fiveStarCount: Int?
    private var coordonnées: Coordonnées
    
    var coordonnéesLieu: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: coordonnées.latitude,
            longitude: coordonnées.longitude)
    }
    
    struct Coordonnées: Hashable, Codable {
        var latitude: Double
        var longitude: Double
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? Int,
              let name = dictionary["name"] as? String,
              let adresse = dictionary["adresse"] as? String,
              let vote = dictionary["vote"] as? Double,
              let description = dictionary["description"] as? String,
              let city = dictionary["city"] as? String,
              let category = dictionary["category"] as? String,
              let coordonnéesDict = dictionary["coordonnées"] as? [String: Double],
              let latitude = coordonnéesDict["latitude"],
              let longitude = coordonnéesDict["longitude"] else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.adresse = adresse
        self.vote = vote
        self.description = description
        self.city = city
        self.category = category
        self.coordonnées = Coordonnées(latitude: latitude, longitude: longitude)
        self.reviewCount = dictionary["reviewCount"] as? Int
        self.oneStarCount = dictionary["oneStarCount"] as? Int
        self.twoStarCount = dictionary["twoStarCount"] as? Int
        self.threeStarCount = dictionary["threeStarCount"] as? Int
        self.fourStarCount = dictionary["fourStarCount"] as? Int
        self.fiveStarCount = dictionary["fiveStarCount"] as? Int
    }
}

struct Comment: Identifiable, Codable, @unchecked Sendable {
    @DocumentID var commentID: String?
    let ownerUid: String
    let dateOfRelease: Int64
    var dateOfVisit: Int64
    var ambianceRating: Int
    var associationsRating: Int
    var content: String
    var generalRating: Double
    var infraRating: Int
    var materialsRating: Int
    var staffRating: Int
    var teachersRating: Int
    var responsesCount: Int?
    var responses: [Response]?
    var title: String
    var isEdited: Bool = false
    
    init?(snapshot: DataSnapshot) {
        guard let value = snapshot.value as? [String: AnyObject],
              let ownerUid = value["ownerUid"] as? String,
              let dateOfRelease = value["dateOfRelease"] as? Int64,
              let dateOfVisit = value["dateOfVisit"] as? Int64,
              let ambianceRating = value["ambianceRating"] as? Int,
              let associationsRating = value["associationsRating"] as? Int,
              let content = value["content"] as? String,
              let generalRating = value["generalRating"] as? Double,
              let infraRating = value["infraRating"] as? Int,
              let materialsRating = value["materialsRating"] as? Int,
              let staffRating = value["staffRating"] as? Int,
              let teachersRating = value["teachersRating"] as? Int,
              let title = value["title"] as? String,
              let isEdited = value["isEdited"] as? Bool,
              let responsesCount = value["responsesCount"] as? Int else {
            return nil
        }

        self.commentID = snapshot.key
        self.ownerUid = ownerUid
        self.dateOfRelease = dateOfRelease
        self.dateOfVisit = dateOfVisit
        self.ambianceRating = ambianceRating
        self.associationsRating = associationsRating
        self.content = content
        self.generalRating = generalRating
        self.infraRating = infraRating
        self.materialsRating = materialsRating
        self.staffRating = staffRating
        self.teachersRating = teachersRating
        self.responsesCount = responsesCount
        self.title = title
        self.isEdited = isEdited
        self.responses = nil
    }
    
    init(ownerUid: String, dateOfRelease: Int64, dateOfVisit: Int64, ambianceRating: Int, associationsRating: Int, content: String, generalRating: Double, infraRating: Int, materialsRating: Int, staffRating: Int, teachersRating: Int, title: String, responsesCount: Int?, responses: [Response]?, isEdited: Bool) {
        self.commentID = UUID().uuidString
        self.ownerUid = ownerUid
        self.dateOfRelease = dateOfRelease
        self.dateOfVisit = dateOfVisit
        self.ambianceRating = ambianceRating
        self.associationsRating = associationsRating
        self.content = content
        self.generalRating = generalRating
        self.infraRating = infraRating
        self.materialsRating = materialsRating
        self.staffRating = staffRating
        self.teachersRating = teachersRating
        self.responsesCount = responsesCount
        self.responses = responses
        self.title = title
        self.isEdited = isEdited
    }
    
    var id: String {
        return commentID ?? UUID().uuidString
    }
}


struct Response: Identifiable, Codable, @unchecked Sendable {
    @DocumentID var responseID: String?
    let ownerUid: String
    let dateOfResponse: Int64
    var responseContent: String
    var responseCount: Int
    var isEdited: Bool = false

    init?(snapshot: DataSnapshot) {
        guard let value = snapshot.value as? [String: AnyObject],
              let ownerUid = value["ownerUid"] as? String,
              let dateOfResponse = value["dateOfResponse"] as? Int64,
              let responseContent = value["responseContent"] as? String,
              let isEdited = value["isEdited"] as? Bool,
              let responseCount = value["responseCount"] as? Int else {
            return nil
        }
        
        self.responseID = snapshot.key
        self.ownerUid = ownerUid
        self.dateOfResponse = dateOfResponse
        self.responseContent = responseContent
        self.isEdited = isEdited
        self.responseCount = responseCount
    }

    init(ownerUid: String, dateOfResponse: Int64, responseContent: String, isEdited: Bool, responseCount: Int) {
        self.responseID = UUID().uuidString
        self.ownerUid = ownerUid
        self.dateOfResponse = dateOfResponse
        self.responseContent = responseContent
        self.isEdited = isEdited
        self.responseCount = responseCount
    }
    
    var id: String {
        return responseID ?? UUID().uuidString
    }
}

struct AnswerToResponse: Identifiable, Codable {
    @DocumentID var answerToResponseID: String?
    let ownerUidAnswerToResponse: String
    let dateOfAnswerToResponse: Int64
    var answerToResponseContent: String
    var answerToResponseCount: Int

    init?(snapshot: DataSnapshot) {
        guard let value = snapshot.value as? [String: AnyObject],
              let ownerUidAnswerToResponse = value["ownerUidAnswerToResponse"] as? String,
              let dateOfAnswerToResponse = value["dateOfAnswerToResponse"] as? Int64,
              let answerToResponseContent = value["answerToResponseContent"] as? String,
              let answerToResponseCount = value["answerToResponseCount"] as? Int else {
            return nil
        }
        
        self.answerToResponseID = snapshot.key
        self.ownerUidAnswerToResponse = ownerUidAnswerToResponse
        self.dateOfAnswerToResponse = dateOfAnswerToResponse
        self.answerToResponseContent = answerToResponseContent
        self.answerToResponseCount = answerToResponseCount
    }

    init(ownerUidAnswerToResponse: String, dateOfAnswerToResponse: Int64, answerToResponseContent: String, answerToResponseCount: Int) {
        self.answerToResponseID = UUID().uuidString
        self.ownerUidAnswerToResponse = ownerUidAnswerToResponse
        self.dateOfAnswerToResponse = dateOfAnswerToResponse
        self.answerToResponseContent = answerToResponseContent
        self.answerToResponseCount = answerToResponseCount
    }
    
    var id: String {
        return answerToResponseID ?? UUID().uuidString
    }
}

extension Comment {
    static let example =  Comment(ownerUid: "1", dateOfRelease: Int64(1720992323), dateOfVisit: Int64(1.0), ambianceRating: 1, associationsRating: 1, content: "11111", generalRating: 3.0, infraRating: 1, materialsRating: 1, staffRating: 1, teachersRating: 1, title: "Guez", responsesCount: 1, responses: nil, isEdited: true)
}

extension Response {
    static let example = Response(ownerUid: "", dateOfResponse: Int64(2), responseContent: "Guez hein", isEdited: true, responseCount: 145)
}
