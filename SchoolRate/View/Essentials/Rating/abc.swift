import SwiftUI

struct Abc: View {
    @FocusState private var isKeyboardVisible: Bool
    @State private var replyText = ""

    var body: some View {
        NavigationStack {
            VStack {
                TextField("", text: $replyText)
                    .focused($isKeyboardVisible)
                    .placeholder(when: replyText.isEmpty) {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.blue)
                    }
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        TextField("Répondre à", text: $replyText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isKeyboardVisible)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .padding()
                    }
                }
            }
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}


struct Abc_Previews: PreviewProvider {
    static var previews: some View {
        Abc()
    }
}
