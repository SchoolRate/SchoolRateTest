//

import SwiftUI
import SwiftUI

struct TopTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: 10, bottomLeading: 5, bottomTrailing: 5, topTrailing: 10)))
            .padding(.horizontal, 24)
    }
}

struct MiddleTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding(.horizontal, 24)
    }
}

struct BottomTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: 5, bottomLeading: 10, bottomTrailing: 10, topTrailing: 5)))
            .padding(.horizontal, 24)
    }
}
