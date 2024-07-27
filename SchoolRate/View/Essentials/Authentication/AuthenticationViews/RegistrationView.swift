//

import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @StateObject var viewModel = RegistrationViewModel()
    
    var body: some View {
        VStack {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 280, height: 280)
            
            VStack(spacing: 4) {
                TextField("Adresse email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .modifier(TopTextFieldModifier())
                
                SecureField("Mot de passe", text: $viewModel.password)
                    .modifier(MiddleTextFieldModifier())
                
                TextField("Nom d'utilisatur", text: $viewModel.username)
                    .textInputAutocapitalization(.never)
                    .modifier(MiddleTextFieldModifier())
            }
            
            Button {
                Task { try await viewModel.createUser() }
            } label: {
                Text("S'inscrire")
                    .modifier(SignInButtonModifier())
            }
            .padding(.vertical)
            
            Spacer()
            
            Divider()
            
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Text("Vous avez déja un compte ?")
    
                    Text("Se connecter")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(colorScheme == .dark ? .white: .black)
                .font(.footnote)
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("SchoolRate")
    }
}

#Preview {
    RegistrationView()
}
