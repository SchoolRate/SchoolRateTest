import SwiftUI
@preconcurrency import Firebase
import FirebaseDatabaseInternal
import FirebaseFirestoreSwift
import Kingfisher

@MainActor
struct ReviewsCell: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var comment: Comment
    
    @State var isEditing: Bool = false
    @FocusState private var isKeyboardVisible: Bool
    
    @State private var responses: [Response] = []
    @ObservedObject var responsesFeed: ResponsesFeedModel
    @StateObject private var responseCreation = ResponseCreationModel()
    @StateObject private var commentCreation = CommentCreationModel()
    @State var replyText: String = ""
    @State private var areResponsesShown: Bool = false
    @State private var username: String = ""
    @State private var showRatingDetails = false
    @State private var showMenu = false
    @State private var isDeleting = false
    @State private var editedCommentText: String = ""
    @State var isEdited: Bool = false
    let deleteReviewString: String = "Êtes-vous sûr de vouloir supprimer cet avis ?"
    
    let isBeingEdited: Bool
    let setEditingComment: (String?) -> Void
    
    func submitReply() {
        Task {
            try await responseCreation.answerToComment(
                responseText: replyText,
                dateOfRelease: Int64(Date().timeIntervalSince1970),
                schoolID: responsesFeed.schoolID,
                commentID: comment.commentID ?? "1",
                isEdited: false
            )
            replyText = ""
            isKeyboardVisible = false
        }
    }
    
    func convertTimestampToRelativeDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "fr_FR")
        
        let relativeDateString = formatter.localizedString(for: date, relativeTo: Date())
        
        let prefixToRemove = "il y a "
        if relativeDateString.lowercased().hasPrefix(prefixToRemove) {
            return String(relativeDateString.dropFirst(prefixToRemove.count))
        } else {
            return relativeDateString
        }
    }

    var lycée: Lycée

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 6) {
                    NavigationLink(destination: ProfileView(userId: comment.ownerUid)) {
                        CircularProfileImage(userId: comment.ownerUid)
                            .scaleEffect(0.75)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        NavigationLink(destination: ProfileView(userId: comment.ownerUid)) {
                            Text(username)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        
                        HStack(spacing: 5) {
                            ForEach(1..<6) { index in
                                Image(systemName: index <= Int(comment.generalRating) ? "star.fill" : "star")
                                    .foregroundColor(index <= Int(comment.generalRating) ? .yellow : .gray)
                            }
                        }
                    }

                    Spacer()
                    
                    Text(convertTimestampToRelativeDate(timestamp: comment.dateOfRelease))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)

                    if !isEditing {
                        Menu {
                            Button("Informations", systemImage: "info.circle") {
                                showRatingDetails.toggle()
                            }

                            Button("Modifier", systemImage: "pencil") {
                                editedCommentText = comment.content
                                withAnimation(.spring()) {
                                    isEditing = true
                                    setEditingComment(comment.commentID)
                                }
                            }

                            Button("Ajuster l'évaluation", systemImage: "star.slash.fill") {
                                // Adjust rating functionality
                            }

                            Button("Partager", systemImage: "square.and.arrow.up") {
                                // Share functionality
                            }

                            Button("Supprimer", role: .destructive) {
                                isDeleting = true
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding(.top, 4)
                        }
                    } else {
                        HStack {
                            Button(action: {
                                withAnimation {
                                    isEditing = false
                                    setEditingComment(nil)
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .scaleEffect(1.5)
                            }

                            Spacer()

                            Button(action: {
                                Task {
                                    do {
                                        try await commentCreation.updateComment(commentID: comment.commentID ?? "1", newContent: editedCommentText, schoolID: String(lycée.id - 1))
                                        withAnimation {
                                            isEditing = false
                                            setEditingComment(nil)
                                        }
                                    } catch {
                                        print("Error updating comment: \(error)")
                                    }
                                }
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .scaleEffect(1.5)
                            }
                        }
                    }
                }
                .alert(isPresented: $isDeleting) {
                    Alert(
                        title: Text(deleteReviewString),
                        primaryButton: .destructive(Text("Supprimer")) {
                            Task {
                                do {
                                    try await commentCreation.deleteComment(commentID: comment.commentID ?? "1", schoolID: String(lycée.id - 1), generalRating: comment.generalRating)
                                    // update ui with small capsule coming from bottom
                                } catch {
                                    print("Error deleting comment: \(error)")
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                if isEditing {
                    TextEditor(text: $editedCommentText)
                        .frame(minHeight: 100, maxHeight: 200)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(.leading, 10)
                } else {
                    Text(comment.content)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                }
            
                HStack {
                    if responses.count > 0 {
                        Button {
                            areResponsesShown.toggle()
                        } label: {
                            HStack {
                                areResponsesShown ? Image(systemName: "arrow.uturn.up") : Image(systemName: "arrow.uturn.down")
                                Text(areResponsesShown ? "Masquer \(responses.count) réponse\(responses.count > 1 ? "s" : "")" : "Afficher \(responses.count) réponse\(responses.count > 1 ? "s" : "")")
                                
                                Spacer()
                            }
                        }
                        .padding(.leading, 20)
                    }
                    
                    if !areResponsesShown {
                        Spacer()
                    }
                    
                    HStack {
                        comment.isEdited ? Text("(modifié)").font(.caption).foregroundColor(.gray) : Text("")
                        Button {
                                isKeyboardVisible = true
                        } label: {
                            Image(systemName: "text.bubble")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    }
                }
                
                if areResponsesShown {
                    ForEach(responses, id: \.id) { response in
                        ResponseCellView(isEdited: comment.isEdited, response: response, schoolID: responsesFeed.schoolID, commentID: comment.commentID ?? "1")
                            .padding()
                            .background(colorScheme == .dark ? Color.black.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.leading, 20)
                    }
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color.black : Color.white)
            .cornerRadius(10)
            .shadow(radius: 2)
            .scaleEffect(isBeingEdited ? 1.015 : (isEditing ? 0.90 : 1.0))
            .blur(radius: isBeingEdited ? 0 : (isEditing ? 3 : 0))
            .opacity(isBeingEdited ? 1.0 : (isEditing ? 0.90 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEditing)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isBeingEdited)
            .onAppear {
                loadUserData()
                loadResponses()
            }
            .animation(.default, value: isKeyboardVisible)
            .sheet(isPresented: $showRatingDetails) {
                NavigationView {
                    RatingDetailsView(comment: comment)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("Informations")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                }
                .presentationDetents([.fraction(0.75), .large])
                .padding()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                TextField("Répondre à \(username)", text: $replyText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isKeyboardVisible)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }
    
    private func loadUserData() {
        Task {
            do {
                let userSnapshot = try await Firestore.firestore().collection("users").document(comment.ownerUid).getDocument()
                await MainActor.run {
                    if let userData = try? userSnapshot.data(as: User.self) {
                        username = userData.username
                        print("fetched user \(username)")
                    } else {
                        print("Error retrieving user data.")
                    }
                }
            } catch {
                print("error fetching \(error)")
            }
        }
    }
    
    private func loadResponses() {
        Task {
            do {
                if let commentID = comment.commentID {
                    try await responsesFeed.fetchAnswersComment(commentID: commentID, schoolID: String(lycée.id - 1))
                    await MainActor.run {
                        responses = responsesFeed.getResponses(for: commentID)
                        print("Responses fetched on appear for comment \(commentID): \(responses.count)")
                    }
                }
            } catch {
                print("error couldn't fetch responses \(error)")
            }
        }
    }
}

struct ResponseCellView: View {
    @State private var showRatingDetails: Bool = false
    @State private var isResponseTextFieldShown: Bool = false
    @State private var replyText: String = ""
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @State private var username: String = ""
    var isEdited: Bool
    var response: Response
    var schoolID: String
    var commentID: String
    @StateObject private var responseCreation = ResponseCreationModel()
    @State private var isDeletingResponse = false
    @State private var responseToDelete: Response?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top, spacing: 10) {
                NavigationLink(destination: ProfileView(userId: response.ownerUid)) {
                    CircularProfileImage(userId: response.ownerUid)
                        .scaleEffect(0.75)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    NavigationLink(destination: ProfileView(userId: response.ownerUid)) {
                        Text(username)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    Text(convertTimestampToRelativeDate(timestamp: response.dateOfResponse))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack {
                    response.isEdited ? Text("(modifié)").font(.caption)                     .foregroundColor(.gray) : Text("")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(.gray)
                    
                    Menu {
                        Button("Modifier", systemImage: "pencil") {
                            // Edit functionality
                        }
                        
                        Button("Ajuster l'évaluation", systemImage: "star.slash.fill") {
                            // Adjust rating functionality
                        }
                        
                        Button("Partager", systemImage: "square.and.arrow.up") {
                            // Share functionality
                        }
                        
                        Button("Supprimer", role: .destructive) {
                            responseToDelete = response
                            isDeletingResponse = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .alert(isPresented: $isDeletingResponse) {
                        Alert(
                            title: Text("Êtes-vous sûr de vouloir supprimer cette réponse ?"),
                            primaryButton: .destructive(Text("Supprimer")) {
                                Task {
                                    do {
                                        try await responseCreation.deleteResponse(responseID: response.id, commentID: commentID, schoolID: schoolID)
                                    } catch {
                                        print("Error deleting response: \(error)")
                                    }
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }

            HStack {
                Text(response.responseContent)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Button {
                    isResponseTextFieldShown.toggle()
                } label: {
                    Image(systemName: "text.bubble")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
        }
        .onAppear {
            Task {
                do {
                    let userSnapshot = try await Firestore.firestore().collection("users").document(response.ownerUid).getDocument()
                    if let userData = try? userSnapshot.data(as: User.self) {
                        username = userData.username
                        print("fetched user \(username)")
                    } else {
                        print("Error retrieving user data.")
                    }
                } catch {
                    print("Error fetching username: \(error)")
                }
            }
        }

        if isResponseTextFieldShown {
            TextField("Répondre à \(username)", text: $replyText, onCommit: {
                Task {
                    try await responseCreation.answerToComment(responseText: replyText, dateOfRelease: Int64(Date().timeIntervalSince1970), schoolID: schoolID, commentID: commentID, targetUserNickname: username, isEdited: isEdited)
                    replyText = ""
                    isResponseTextFieldShown = false
                }
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.leading, 10)
        }
    }
}

struct RatingStars: View {
    let rating: Int
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        HStack {
            ForEach(1..<6) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundColor(index <= rating ? .yellow : .gray)
            }
        }
    }
}

struct RatingDetailsView: View {
    @Environment(\.dismiss) var dismiss
    var comment: Comment
    
    func convertTimestampToDateComplete(timestamp: Int64) -> String {
        return Date(timeIntervalSince1970: TimeInterval(timestamp)).formatted(date: .complete, time: .complete)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Titre:")
                Spacer()
                Text(comment.title)
            }
            HStack {
                Text("Date de publication:")
                Spacer()
                Text(convertTimestampToDateComplete(timestamp: comment.dateOfRelease))
            }
            HStack {
                Text("Date de visite:")
                Spacer()
                Text(convertTimestampToDateComplete(timestamp: comment.dateOfVisit))
            }
            .padding(.vertical, 20)
            
            HStack {
                Text("Général")
                Spacer()
                RatingStars(rating: Int(comment.generalRating.rounded()))
            }
            .padding(.vertical, 4)
            
            HStack {
                Text("Corps enseignant")
                Spacer()
                RatingStars(rating: comment.teachersRating)
            }
            .padding(.vertical, 4)
            
            HStack {
                Text("Personnel")
                Spacer()
                RatingStars(rating: comment.staffRating)
            }
            .padding(.vertical, 4)
            
            HStack {
                Text("Infrastructures")
                Spacer()
                RatingStars(rating: comment.infraRating)
            }
            .padding(.vertical, 4)
            
            HStack {
                Text("Ambiance")
                Spacer()
                RatingStars(rating: comment.ambianceRating)
            }
            .padding(.vertical, 4)
            
            HStack {
                Text("Associations")
                Spacer()
                RatingStars(rating: comment.associationsRating)
            }
            .padding(.vertical, 4)
            
            HStack {
                Text("Matériel")
                Spacer()
                RatingStars(rating: comment.materialsRating)
            }
            .padding(.vertical, 4)
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "x.circle.fill")
                        .foregroundStyle(.gray)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension ResponseCellView {
    func convertTimestampToRelativeDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "fr_FR")
        
        let relativeDateString = formatter.localizedString(for: date, relativeTo: Date())
        
        let prefixToRemove = "il y a "
        if relativeDateString.lowercased().hasPrefix(prefixToRemove) {
            return String(relativeDateString.dropFirst(prefixToRemove.count))
        } else {
            return relativeDateString
        }
    }
}


#Preview {
    let previewViewModel = SchoolsViewModel()
    let exampleLycée = previewViewModel.listObject.first ?? Lycée.example
    return ReviewsCell(
        comment: Comment.example,
        responsesFeed: ResponsesFeedModel(schoolID: "1"),
        isBeingEdited: false,
        setEditingComment: { _ in },
        lycée: exampleLycée
    )
}

