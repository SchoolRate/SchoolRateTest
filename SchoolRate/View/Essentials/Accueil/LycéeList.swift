import SwiftUI

struct LycéeList: View {
    @State private var searchText = ""
    @StateObject private var viewModel = SchoolsViewModel()
    @ObservedObject var responsesFeed = ResponsesFeedModel(schoolID: "1")
    @ObservedObject var responseCreation = ResponseCreationModel()
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    Spacer().padding(.top, 4)
                    
                    TextField("Rechercher un établissement", text: $searchText)
                        .padding(7)
                        .background(Color(.systemGray6))
                        .frame(width: geometry.size.width * 0.9)
                        .cornerRadius(8)
                        .padding(.horizontal, 10)
                    
                    Spacer().padding(.top, 10)
                    
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.listObject.isEmpty {
                        Text("Aucun lycée trouvé")
                    } else {
                        LazyVStack(spacing: getSpacing(for: geometry.size.width)) {
                            ForEach(viewModel.listObject) { lycee in
                                NavigationLink(destination: LycéeDétail(lycée: lycee, responsesFeed: responsesFeed, responseCreation: responseCreation)) {
                                    LycéeRow(lycée: lycee)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Lycées")
                .navigationBarTitleDisplayMode(.automatic)
            }
        }
        .onAppear {
            if viewModel.listObject.isEmpty {
                viewModel.observeListObject()
            }
        }
    }
    
    func getSpacing(for width: CGFloat) -> CGFloat {
        if width > 429 {
            return 230
        } else {
            return 210
        }
    }
}

#Preview {
    LycéeList(responsesFeed: ResponsesFeedModel(schoolID: "1"), responseCreation: ResponseCreationModel())
}
