import SwiftUI
import CoreML
import Firebase
import MapKit

struct LycéeDétail: View {
    @State private var isShowingSheet = false
    @State private var generalRating = 1.0
    @State private var teachersRating = 1
    @State private var staffRating = 1
    @State private var infraRating = 1
    @State private var ambianceRating = 1
    @State private var associationsRating = 1
    @State private var materialRating = 1
    @State private var title = ""
    @State private var content = ""
    @State private var dateVisit = Date()
    @State private var dateOfRelease = Timestamp()
    @State private var responses = [Response]()
    @State private var isEdited = false
    
    @State private var showThankYouMessage = false
    @State private var messageOpacity = 0.0
    @State private var messageScale = 0.5
    
    @State private var dragOffset: CGFloat = 0
    
    @StateObject var commentsFeed: CommentsFeedModel
    @StateObject var responsesFeed: ResponsesFeedModel
    @ObservedObject var responseCreation: ResponseCreationModel
    
    @State private var showCommentFetchedCapsule = false
    @State private var commentsFetchedCount = 0
    @State private var previousCommentCount = 0
    
    @State private var topKeywords: [(String, Int)] = []
    @State private var selectedKeywords: Set<String> = []
    
    @State private var answerToResponse = AnswerToResponse(ownerUidAnswerToResponse: "", dateOfAnswerToResponse: 0, answerToResponseContent: "", answerToResponseCount: 0)
    
    @State private var editingCommentID: String?
    
    var lycée: Lycée
    
    init(lycée: Lycée, responsesFeed: ResponsesFeedModel, responseCreation: ResponseCreationModel) {
        self.lycée = lycée
        print("Initializing LycéeDétail with lycée: \(lycée.name)")
        _commentsFeed = StateObject(wrappedValue: CommentsFeedModel(schoolID: String(lycée.id - 1)))
        _responsesFeed = StateObject(wrappedValue: ResponsesFeedModel(schoolID: String(lycée.id - 1)))
        self.responseCreation = responseCreation
    }
    
    func convertTimeStampToSeconds(_ timestamp: Timestamp) -> Int64 {
        return timestamp.seconds
    }
    
    func formatNumber(ratingFormatted: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: ratingFormatted))!
    }
    
    func ratingPercentage(starCount: Int?) -> CGFloat {
        guard let starCount = starCount, let reviewCount = lycée.reviewCount, reviewCount > 0 else {
            return 0
        }
        return CGFloat(starCount) / CGFloat(reviewCount)
    }
    
    func extractAndRankKeywords() {
        let allKeywords = KeywordExtractionService.shared.extractKeywords(from: commentsFeed.comments)
        
        for (keyword, count) in allKeywords {
            print("Keyword: \(keyword), Count: \(count), Length: \(keyword.count)")
        }
        
        topKeywords = allKeywords.filter { keyword, count in
            count >= 5 && keyword.count <= 6
        }
        .sorted { $0.1 > $1.1 }
        .prefix(6)
        .map { ($0.0, $0.1) }
    }

    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack {
                        HeaderView(lycée: lycée, geometry: geometry)
                        DetailsView(lycée: lycée)
                        
                        HStack {
                            Text("Notes et avis")
                                .font(.title)
                            
                            Spacer()
                            
                            Button {
                                isShowingSheet.toggle()
                            } label: {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 25))
                                    .tint(.blue)
                            }
                            .sheet(isPresented: $isShowingSheet) {
                                RatingView(
                                    generalRating: $generalRating,
                                    teachersRating: $teachersRating,
                                    staffRating: $staffRating,
                                    infraRating: $infraRating,
                                    ambianceRating: $ambianceRating,
                                    associationsRating: $associationsRating,
                                    materialRating: $materialRating,
                                    dateVisit: $dateVisit,
                                    responses: $responses,
                                    showThankYouMessage: $showThankYouMessage,
                                    isEdited: $isEdited, dateOfRelease: $dateOfRelease,
                                    content: $content,
                                    title: $title,
                                    schoolID: String(lycée.id - 1)
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                        
                        HStack(alignment: .bottom) {
                            Text(formatNumber(ratingFormatted: lycée.vote))
                                .font(.system(size: 40, weight: .light, design: .rounded))
                                .fontWeight(.bold)
                                .offset(y: 7)
                            
                            Text("sur 5")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                            
                            Text(lycée.reviewCount == nil ? "Aucun avis" : "\(lycée.reviewCount!) avis")
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .offset(x: 20)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 5) {
                                ForEach((1...5).reversed(), id: \.self) { star in
                                    HStack {
                                        Spacer()
                                        HStack(spacing: 2) {
                                            ForEach(0..<star, id: \.self) { _ in
                                                Image(systemName: "star.fill")
                                                    .resizable()
                                                    .frame(width: 10, height: 10)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .frame(width: 100, height: 3)
                                                .foregroundColor(Color.gray.opacity(0.5))
                                            Capsule()
                                                .frame(width: 100 * ratingPercentage(starCount: {
                                                    switch star {
                                                    case 1: return lycée.oneStarCount
                                                    case 2: return lycée.twoStarCount
                                                    case 3: return lycée.threeStarCount
                                                    case 4: return lycée.fourStarCount
                                                    case 5: return lycée.fiveStarCount
                                                    default: return 0
                                                    }
                                                }()), height: 3)
                                                .foregroundColor(Color.black)
                                        }
                                        .frame(width: 110, height: 3)
                                    }
                                }
                            }
                            .padding(.bottom, 3.4)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        Divider()
                            .padding(.bottom, 20)
                        
                        if commentsFeed.comments.isEmpty {
                            NoCommentsView(isShowingSheet: $isShowingSheet)
                        } else {
                            if !topKeywords.isEmpty {
                                KeywordsView(topKeywords: $topKeywords, selectedKeywords: $selectedKeywords)
                            }
                            
                            CommentsView(commentsFeed: commentsFeed, responsesFeed: responsesFeed, lycée: lycée, selectedKeywords: $selectedKeywords, editingCommentID: $editingCommentID)
                        }
                    }
                    .navigationTitle(lycée.name)
                    .navigationBarTitleDisplayMode(.inline)
                }
                
                VStack {
                    Spacer()
                    CommentFetchedCapsule(count: commentsFetchedCount, dragOffset: $dragOffset) {
                        showCommentFetchedCapsule = false
                        dragOffset = 0
                    }
                    .opacity(showCommentFetchedCapsule ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showCommentFetchedCapsule)
                    .offset(y: -60)
                }
            }
            .overlay(
                ThankYouMessageView(showThankYouMessage: $showThankYouMessage, messageOpacity: $messageOpacity, messageScale: $messageScale)
            )
            .onAppear {
                fetchComments()
            }
            .refreshable {
                refreshComments()
            }
        }
    }
    
    func fetchComments() {
        Task {
            do {
                try await commentsFeed.fetchCommentsSchool(schoolID: commentsFeed.schoolID)
                previousCommentCount = commentsFeed.comments.count
                print("Fetched \(commentsFeed.comments.count) comments")
                for comment in commentsFeed.comments {
                    if let commentID = comment.commentID {
                        Task {
                            do {
                                try await responsesFeed.fetchAnswersComment(commentID: commentID, schoolID: commentsFeed.schoolID)
                            } catch {
                                print("Error fetching comments on refresh: \(error)")
                            }
                        }
                    }
                }
                extractAndRankKeywords()
            } catch {
                print("Error fetching comments on refresh: \(error)")
            }
        }
    }
    
    func refreshComments() {
        Task {
            do {
                let oldCount = commentsFeed.comments.count
                try await commentsFeed.fetchCommentsSchool(schoolID: commentsFeed.schoolID)
                let newCount = commentsFeed.comments.count
                let newCommentsCount = newCount - oldCount

                if newCommentsCount > 0 {
                    commentsFetchedCount = newCommentsCount
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        showCommentFetchedCapsule = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        withAnimation {
                            showCommentFetchedCapsule = false
                        }
                    }
                }
                
                previousCommentCount = newCount

                print("Fetched \(commentsFeed.comments.count) comments")
                for comment in commentsFeed.comments {
                    if let commentID = comment.commentID {
                        Task {
                            do {
                                try await responsesFeed.fetchAnswersComment(commentID: commentID, schoolID: commentsFeed.schoolID)
                            } catch {
                                print("Error fetching comments on refresh: \(error)")
                            }
                        }
                    }
                }
                extractAndRankKeywords()
            } catch {
                print("Error fetching comments on refresh: \(error)")
            }
        }
    }
}

struct HeaderView: View {
    var lycée: Lycée
    var geometry: GeometryProxy

    var body: some View {
        VStack {
            MapView(coordonnée: lycée.coordonnéesLieu)
                .frame(width: geometry.size.width, height: geometry.size.height * 0.42)

            CircleImage(lycée: lycée)
                .offset(y: -130)
                .padding(.bottom, -130)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DetailsView: View {
    var lycée: Lycée

    var body: some View {
        VStack(alignment: .leading) {
            Text(lycée.name)
                .font(.title)
                .padding(.bottom, 10)

            HStack {
                Text("\(lycée.category)")

                Spacer()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Divider()

            Text("À propos de \(lycée.name)")
                .font(.title2)
                .padding(.bottom, 5)

            Text(lycée.description)
                .padding(.bottom, 10)
        }
        .padding(.horizontal)
    }
}

struct NoCommentsView: View {
    @Binding var isShowingSheet: Bool

    var body: some View {
        VStack(alignment: .center) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 120))
                .foregroundStyle(.primary)
            VStack {
                Text("""
                Ce lycée n'a pas d'avis. Soyez la première personne à \(Text("commenter.")
                    .underline()
                    .foregroundStyle(Color(.lightGray))
                    .fontWeight(.bold))
                """)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .onTapGesture {
                        isShowingSheet.toggle()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal)
    }
}

struct CommentsView: View {
    @ObservedObject var commentsFeed: CommentsFeedModel
    @ObservedObject var responsesFeed: ResponsesFeedModel
    @State private var keyboardHeight: CGFloat = 0
    var lycée: Lycée
    @Binding var selectedKeywords: Set<String>
    @Binding var editingCommentID: String?
    
    @Namespace private var animation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(commentsFeed.comments, id: \.id) { comment in
                let containsKeywords = selectedKeywords.isEmpty || selectedKeywords.allSatisfy { comment.content.lowercased().contains($0.lowercased()) }
                
                ReviewsCell(comment: comment,
                            responsesFeed: responsesFeed,
                            replyText: "",
                            isBeingEdited: editingCommentID == comment.commentID,
                            setEditingComment: { id in
                    editingCommentID = id
                }, lycée: lycée)
                .onAppear(perform: addKeyboardObservers)
                .onDisappear(perform: removeKeyboardObservers)
                .opacity(editingCommentID == nil || editingCommentID == comment.commentID ? 1.0 : 0.5)
                .opacity(containsKeywords ? 1.0 : 0.5)
                .scaleEffect(scaleEffect(for: comment))
                .blur(radius: blur(for: comment))
                .shadow(color: shadowColor(for: comment), radius: 10, x: 0, y: 5)
                .zIndex(containsKeywords ? 1 : 0)
                .matchedGeometryEffect(id: comment.id, in: animation)
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5), value: selectedKeywords)
            }
        }
        .padding(.horizontal)
    }
    
    private func scaleEffect(for comment: Comment) -> CGFloat {
        if editingCommentID != nil {
            return editingCommentID == comment.commentID ? 1.015 : 0.90
        } else if selectedKeywords.isEmpty {
            return 1
        }
        
        let containsAllKeywords = selectedKeywords.allSatisfy { comment.content.lowercased().contains($0.lowercased()) }
        return containsAllKeywords ? 1 : 0.90
    }
    
    private func blur(for comment: Comment) -> CGFloat {
        if editingCommentID != nil {
            return editingCommentID == comment.commentID ? 0 : 3
        }
        return 0
    }
    
    private func shadowColor(for comment: Comment) -> Color {
        if selectedKeywords.isEmpty {
            return Color.black.opacity(0.1)
        }
        
        let containsAllKeywords = selectedKeywords.allSatisfy { comment.content.lowercased().contains($0.lowercased()) }
        return containsAllKeywords ? Color.black.opacity(0.1) : Color.clear
    }
    
    private func addKeyboardObservers() {
        let keyboardFrameEndUserInfoKey = UIResponder.keyboardFrameEndUserInfoKey
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame: NSValue = notification.userInfo?[keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                Task { @MainActor in
                    self.keyboardHeight = keyboardRectangle.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in
                self.keyboardHeight = 0
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}



struct ThankYouMessageView: View {
    @Binding var showThankYouMessage: Bool
    @Binding var messageOpacity: Double
    @Binding var messageScale: Double

    var body: some View {
        Group {
            if showThankYouMessage {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .scaleEffect(2)
                    Text("Avis envoyé")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Merci pour votre avis")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.secondary)
                .padding(30)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .frame(width: 210, height: 210)

                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 3)
                            .scaleEffect(messageScale)
                            .frame(width: 210, height: 210)
                    }
                )
                .opacity(messageOpacity)
                .scaleEffect(messageScale)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        messageOpacity = 1.0
                        messageScale = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            messageOpacity = 0.0
                            messageScale = 1.2
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showThankYouMessage = false
                        }
                    }
                }
            }
        }
    }
}

struct CommentFetchedCapsule: View {
    let count: Int
    @Binding var dragOffset: CGFloat
    var onDismiss: () -> Void
    
    var body: some View {
        Capsule()
            .fill(Color.black)
            .frame(width: 200, height: 40)
            .overlay(
                Text(count == 1 ? "1 commentaire récupéré" : "\(count) commentaires récupérés")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
            )
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 20 {
                            withAnimation {
                                dragOffset = 200
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDismiss()
                            }
                        } else {
                            withAnimation {
                                dragOffset = 0
                            }
                        }
                    }
            )
    }
}

struct KeywordCapsule: View {
    let keyword: String
    let count: Int
    let isSelected: Bool
    let isOtherSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(keyword)
                Text("(\(count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected || !isOtherSelected ? Color.white : Color.gray.opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(Color.black, lineWidth: 1.5)
                            .opacity(isSelected ? 1 : 0.5)
                    )
            )
            .foregroundColor(isSelected || !isOtherSelected ? .primary : .secondary)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOtherSelected)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct KeywordsView: View {
    @Binding var topKeywords: [(String, Int)]
    @Binding var selectedKeywords: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ForEach(topKeywords.prefix(3), id: \.0) { keyword, count in
                    KeywordCapsule(
                        keyword: keyword,
                        count: count,
                        isSelected: selectedKeywords.contains(keyword),
                        isOtherSelected: !selectedKeywords.isEmpty && !selectedKeywords.contains(keyword)
                    ) {
                        toggleKeyword(keyword)
                    }
                }
            }
            if topKeywords.count > 3 {
                HStack(spacing: 10) {
                    ForEach(topKeywords.dropFirst(3), id: \.0) { keyword, count in
                        KeywordCapsule(
                            keyword: keyword,
                            count: count,
                            isSelected: selectedKeywords.contains(keyword),
                            isOtherSelected: !selectedKeywords.isEmpty && !selectedKeywords.contains(keyword)
                        ) {
                            toggleKeyword(keyword)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    private func toggleKeyword(_ keyword: String) {
        if selectedKeywords.contains(keyword) {
            selectedKeywords.remove(keyword)
        } else {
            selectedKeywords.insert(keyword)
        }
    }
}

#Preview {
    let previewViewModel = SchoolsViewModel()
    LycéeDétail(lycée: previewViewModel.listObject.first ?? Lycée.example, responsesFeed: ResponsesFeedModel(schoolID: "1"), responseCreation: ResponseCreationModel())
}

extension Lycée {
    static let example = Lycée(dictionary: [
        "id": 1,
        "name": "Example Lycée",
        "adresse": "123 Example Street",
        "vote": 4.5,
        "description": "This is an example lycée for preview purposes.",
        "city": "Example City",
        "category": "Public",
        "coordonnées": ["latitude": 48.8566, "longitude": 2.3522],
        "reviewCount": 464,
        "oneStarCount": 200,
        "twoStarCount": 100,
        "threeStarCount": 100,
        "fourStarCount": 60,
        "fiveStarCount": 4
    ])!
}
