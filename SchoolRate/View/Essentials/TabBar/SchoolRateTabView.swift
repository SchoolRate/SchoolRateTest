//

import SwiftUI

struct SchoolRateTabView: View {
    @State private var selectedTab = 0
    @StateObject var viewModel = ProfileModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LycéeList()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                }
                .onAppear { selectedTab = 0 }
                .tag(0)
            
            SchoolsRankView()
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                }
                .onAppear { selectedTab = 1 }
                .tag(1)
            
            Editorial()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "newspaper.fill" : "newspaper")
                        .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
                }
                .onAppear { selectedTab = 2 }
                .tag(2)
            
            ProfileView(userId: viewModel.currentUser?.id ?? "1")
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.crop.circle.fill" : "person.crop.circle")
                        .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                }
                .onAppear {
                    selectedTab = 3
                }
                .tag(3)
        }
        .tint(.black)
    }
}

#Preview {
    SchoolRateTabView()
}
