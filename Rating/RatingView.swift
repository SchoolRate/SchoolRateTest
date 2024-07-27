import SwiftUI
import Firebase
import CoreML
import NaturalLanguage

struct RatingView: View {
    @StateObject var viewModel = CommentCreationModel()
    
    @Binding var generalRating: Double
    @Binding var teachersRating: Int
    @Binding var staffRating: Int
    @Binding var infraRating: Int
    @Binding var ambianceRating: Int
    @Binding var associationsRating: Int
    @Binding var materialRating: Int
    @Binding var dateVisit: Date
    @Binding var responses: [Response]
    @Binding var showThankYouMessage: Bool
    @Binding var isEdited: Bool
    
    @State private var showingNegativeAlert = false
    
    func convertToDateTimeStamp(_ date: Date) -> Int64 {
        return Int64(date.timeIntervalSince1970)
    }
    
    func convertTimeStampToSeconds(_ timestamp: Timestamp) -> Int64 {
        return timestamp.seconds
    }
    
    @Binding var dateOfRelease: Timestamp
    
    private var user: User? {
        return UserService.shared.currentUser
    }
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var content: String
    @Binding var title: String
    @State var selection = "Corps enseignant"
    @State var schoolID: String
    
    func classifySentiment() -> String? {
            do {
                let model = try CommentsClassifierML(configuration: MLModelConfiguration()).model
                let predictor = try NLModel(mlModel: model)
                return predictor.predictedLabel(for: content)
            } catch {
                print("Error classifying sentiment: \(error)")
                return nil
            }
        }
    
    let fields = ["Corps enseignant", "Personnel", "Infrastructures", "Ambiance", "Associations", "Matériel"]
    
    func currentRating() -> Int {
        switch selection {
        case "Corps enseignant":
            return teachersRating
        case "Personnel":
            return staffRating
        case "Infrastructures":
            return infraRating
        case "Ambiance":
            return ambianceRating
        case "Associations":
            return associationsRating
        case "Matériel":
            return materialRating
        default:
            return 0
        }
    }
    
    func calculateMeanRating() -> Double {
        let total = Double(Int(teachersRating)) + Double(Int(staffRating)) + Double(Int(infraRating)) + Double(Int(ambianceRating)) + Double(Int(associationsRating)) + Double(Int(materialRating))
        return Double(total / 6)
    }
                                
    func updateRating(_ newRating: Int) {
        switch selection {
        case "Corps enseignant":
            teachersRating = newRating
        case "Personnel":
            staffRating = newRating
        case "Infrastructures":
            infraRating = newRating
        case "Ambiance":
            ambianceRating = newRating
        case "Associations":
            associationsRating = newRating
        case "Matériel":
            materialRating = newRating
        default:
            break
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack {
                    VStack {
                        HStack {
                            VStack {
                                HStack {
                                    ForEach(1..<6) { index in
                                        Image(systemName: index <= currentRating() ? "star.fill" : "star")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(index <= currentRating() ? .yellow : .gray)
                                            .onTapGesture {
                                                updateRating(index)
                                            }
                                            .gesture(
                                                DragGesture()
                                                    .onChanged { value in
                                                        let starWidth: CGFloat = 35
                                                        let newRating = Int(value.location.x / starWidth) + 1
                                                        updateRating(min(max(newRating, 1), 5))
                                                    }
                                            )
                                    }
                                }
                                
                                Picker("Domaine à noter", selection: $selection) {
                                    ForEach(fields, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.automatic)
                                .tint(.blue)
                                .toolbar {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        Button(action: {
                                            generalRating = Double(calculateMeanRating())
                                            if let sentiment = classifySentiment(), sentiment == "negative" {
                                                showingNegativeAlert = true
                                            } else {
                                                Task {
                                                    try await viewModel.uploadComment(
                                                        generalRating: generalRating,
                                                        teachersRating: teachersRating,
                                                        staffRating: staffRating,
                                                        infraRating: infraRating,
                                                        ambianceRating: ambianceRating,
                                                        associationsRating: associationsRating,
                                                        materialRating: materialRating,
                                                        dateVisit: convertToDateTimeStamp(dateVisit),
                                                        dateOfRelease: convertTimeStampToSeconds(dateOfRelease),
                                                        title: title,
                                                        reviewText: content,
                                                        schoolID: schoolID,
                                                        responses: responses, isEdited: isEdited
                                                    )
                                                    dismiss()
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                        showThankYouMessage = true
                                                    }
                                                }
                                            }
                                        }) {
                                            Text("Publier")
                                        }
                                        .tint(.primary)
                                        .fontWeight(.bold)
                                        .disabled(!(title.count >= 15 && title.count <= 25) || !(content.count >= 100 && content.count <= 300))
                                    }
                                    
                                    ToolbarItem(placement: .topBarLeading) {
                                        Button("Annuler") {
                                            dismiss()
                                        }
                                        .tint(.primary)
                                        .fontWeight(.bold)
                                    }
                                }       
                                .alert("Êtes-vous sûr de vouloir publier ce message ?", isPresented: $showingNegativeAlert) {
                                    Button("Non", role: .cancel) { }
                                    Button("Oui") {
                                        Task {
                                            try await viewModel.uploadComment(
                                                generalRating: generalRating,
                                                teachersRating: teachersRating,
                                                staffRating: staffRating,
                                                infraRating: infraRating,
                                                ambianceRating: ambianceRating,
                                                associationsRating: associationsRating,
                                                materialRating: materialRating,
                                                dateVisit: convertToDateTimeStamp(dateVisit),
                                                dateOfRelease: convertTimeStampToSeconds(dateOfRelease),
                                                title: title,
                                                reviewText: content,
                                                schoolID: schoolID,
                                                responses: responses, isEdited: isEdited
                                            )
                                            dismiss()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                showThankYouMessage = true
                                            }
                                        }
                                    }
                                } message: {
                                    Text("Le contenu de votre message semble négatif. Voulez-vous vraiment le publier ?")
                                }
                                
                                DatePicker("Date de visite", selection: $dateVisit, displayedComponents: [.date])
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Divider()
                    HStack {
                        Text("Titre: ")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        TextField("", text: $title)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    
                    Divider()
                        .padding(.bottom, 5)
                    
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.gray, lineWidth: 2)
                            .frame(width: geometry.size.width * 0.92, height: geometry.size.height * 0.75)
                        
                        TextEditor(text: $content)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .padding()
                        
                        var color: Color? {
                            if content.count > 300 || content.count < 100 {
                                return .red
                            } else if content.count == 300 {
                                return .orange
                            } else {
                                return nil
                            }
                        }
                        
                        Text("\(content.count)/300")
                            .font(.system(size: 13))
                            .foregroundColor(color)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding()
                    }
                    .padding(.bottom, 10)
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    RatingView(viewModel: CommentCreationModel(), generalRating:  .constant(1.0), teachersRating: .constant(1), staffRating:  .constant(1), infraRating:  .constant(1), ambianceRating:  .constant(1), associationsRating:  .constant(1), materialRating:  .constant(1), dateVisit: .constant(Date()), responses: .constant([Response]()), showThankYouMessage: .constant(true), isEdited: .constant(false), dateOfRelease: .constant(Timestamp()), content: .constant("ececececececeeececef huregvysgtvèbesrgtvey huregvysgtvèbesrgtvey huregvysgtvèbesrgtvey huregvysgtvèbesrgtvey"), title: .constant(""), schoolID: "")
}
