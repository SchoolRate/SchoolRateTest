//

import SwiftUI

struct SignInButtonModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(colorScheme == .dark ? .black : .white)
            .frame(width: 352, height: 44)
            .background(colorScheme == .dark ? .white : .black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .clipShape(UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: 5, bottomLeading: 10, bottomTrailing: 10, topTrailing: 5)))
        
    }
}
