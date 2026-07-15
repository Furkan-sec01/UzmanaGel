import SwiftUI

extension Color {
    // Dynamic System Colors supporting Light and Dark modes
    static let themePrimary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.38, green: 0.50, blue: 0.95, alpha: 1.0) : UIColor(red: 0.18, green: 0.30, blue: 0.80, alpha: 1.0)
    })
    
    static let themeSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.65, green: 0.40, blue: 0.95, alpha: 1.0) : UIColor(red: 0.45, green: 0.20, blue: 0.80, alpha: 1.0)
    })
    
    static let themeBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0) : UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)
    })
    
    static let themeCardBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.13, green: 0.13, blue: 0.16, alpha: 0.8) : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9)
    })
    
    static let themeBorder = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.22, green: 0.22, blue: 0.26, alpha: 0.6) : UIColor(red: 0.90, green: 0.91, blue: 0.95, alpha: 0.8)
    })
    
    static let themeText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.white : UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
    })
    
    static let themeSecondaryText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.lightGray : UIColor(red: 0.40, green: 0.40, blue: 0.45, alpha: 1.0)
    })
    
    static let themeSuccess = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.20, green: 0.75, blue: 0.45, alpha: 1.0) : UIColor(red: 0.10, green: 0.60, blue: 0.35, alpha: 1.0)
    })
    
    static let themeWarning = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.98, green: 0.70, blue: 0.20, alpha: 1.0) : UIColor(red: 0.85, green: 0.55, blue: 0.10, alpha: 1.0)
    })
    
    static let themeError = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.95, green: 0.30, blue: 0.30, alpha: 1.0) : UIColor(red: 0.80, green: 0.20, blue: 0.20, alpha: 1.0)
    })
}

// Visual Effects & Glassmorphism View Modifiers
struct GlassmorphicContainer: ViewModifier {
    var cornerRadius: CGFloat = Constants.radiusL
    var shadowRadius: CGFloat = Constants.shadowRadiusM
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.themeCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.themeBorder, lineWidth: 1.5)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.04), radius: shadowRadius, x: 0, y: 4)
    }
}

extension View {
    func glassmorphic(cornerRadius: CGFloat = Constants.radiusL, shadowRadius: CGFloat = Constants.shadowRadiusM) -> some View {
        self.modifier(GlassmorphicContainer(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}

// Premium Shimmer Effect for Loading state
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let size = geo.size
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.15), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: -size.width + (phase * size.width * 2))
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
            .mask(content)
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
}
