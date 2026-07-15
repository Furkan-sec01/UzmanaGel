import SwiftUI

// MARK: - CardView Component
struct CardView<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = Constants.radiusL
    var shadowRadius: CGFloat = Constants.shadowRadiusM
    
    init(cornerRadius: CGFloat = Constants.radiusL, shadowRadius: CGFloat = Constants.shadowRadiusM, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Constants.paddingM)
            .glassmorphic(cornerRadius: cornerRadius, shadowRadius: shadowRadius)
    }
}

// MARK: - BadgeView Component
struct BadgeView: View {
    let text: String
    var style: BadgeStyle = .primary
    
    enum BadgeStyle {
        case primary, secondary, success, warning, error, neutral
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Color.themePrimary.opacity(0.12)
            case .secondary: return Color.themeSecondary.opacity(0.12)
            case .success: return Color.themeSuccess.opacity(0.12)
            case .warning: return Color.themeWarning.opacity(0.12)
            case .error: return Color.themeError.opacity(0.12)
            case .neutral: return Color.themeSecondaryText.opacity(0.12)
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary: return Color.themePrimary
            case .secondary: return Color.themeSecondary
            case .success: return Color.themeSuccess
            case .warning: return Color.themeWarning
            case .error: return Color.themeError
            case .neutral: return Color.themeSecondaryText
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(.footnote)
            .fontWeight(.semibold)
            .padding(.horizontal, Constants.paddingS + 2)
            .padding(.vertical, Constants.paddingXS)
            .background(style.backgroundColor)
            .foregroundColor(style.textColor)
            .clipShape(Capsule())
    }
}

// MARK: - AvatarView Component
struct AvatarView: View {
    let imageURLString: String?
    let size: CGFloat
    var isEditable: Bool = false
    var onEditTap: (() -> Void)? = nil
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let urlString = imageURLString, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        placeholderView
                            .shimmer()
                    }
                } else {
                    placeholderView
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.themeBorder, lineWidth: 1.5))
            
            if isEditable {
                Button {
                    onEditTap?()
                } label: {
                    Image(systemName: "camera.circle.fill")
                        .resizable()
                        .frame(width: size * 0.28, height: size * 0.28)
                        .symbolRenderingMode(.multicolor)
                        .background(Color.white.clipShape(Circle()))
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .offset(x: -2, y: -2)
            }
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            Color.themeSecondaryText.opacity(0.15)
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color.themeSecondaryText.opacity(0.5))
                .padding(size * 0.25)
        }
    }
}

// MARK: - SectionHeaderView Component
struct SectionHeaderView: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Constants.spacingXS) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.themeText)
                if let sub = subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }
            }
            Spacer()
            if let actTitle = actionTitle, let act = action {
                Button(action: act) {
                    Text(actTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.themePrimary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, Constants.paddingS)
    }
}

// MARK: - StatCard Component
struct StatCard: View {
    let title: String
    let value: String
    var changeText: String? = nil
    var iconName: String
    var color: Color = Color.themePrimary
    
    @State private var animateValue: Bool = false
    
    var body: some View {
        CardView(cornerRadius: Constants.radiusL, shadowRadius: Constants.shadowRadiusS) {
            VStack(alignment: .leading, spacing: Constants.spacingM) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: iconName)
                            .foregroundColor(color)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Spacer()
                    if let change = changeText {
                        Text(change)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(change.hasPrefix("+") ? Color.themeSuccess : Color.themeSecondaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(change.hasPrefix("+") ? Color.themeSuccess.opacity(0.1) : Color.themeSecondaryText.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                VStack(alignment: .leading, spacing: Constants.spacingXS) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                        .lineLimit(1)
                    
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeText)
                        .minimumScaleFactor(0.85)
                        .scaleEffect(animateValue ? 1.0 : 0.95)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                animateValue = true
            }
        }
    }
}

// MARK: - LoadingView Component
struct LoadingView: View {
    var message: String = "Yükleniyor..."
    
    var body: some View {
        VStack(spacing: Constants.spacingM) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.themePrimary)
            Text(message)
                .font(.callout)
                .foregroundColor(Color.themeSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground)
    }
}

// MARK: - EmptyStateView Component
struct EmptyStateView: View {
    let iconName: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: Constants.spacingL) {
            ZStack {
                Circle()
                    .fill(Color.themeSecondaryText.opacity(0.06))
                    .frame(width: 80, height: 80)
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(Color.themeSecondaryText.opacity(0.7))
            }
            
            VStack(spacing: Constants.spacingS) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.themeText)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.paddingXL)
            }
            
            if let btnTitle = buttonTitle, let act = action {
                Button(action: act) {
                    Text(btnTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Constants.paddingL)
                        .padding(.vertical, Constants.paddingM)
                        .background(Color.themePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground)
    }
}

// MARK: - ErrorStateView Component
struct ErrorStateView: View {
    let title: String
    let message: String
    var buttonTitle: String = "Tekrar Dene"
    var action: (() -> Void)? = nil
    
    init(title: String = "Bir Hata Oluştu", message: String, buttonTitle: String = "Tekrar Dene", action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    // Support trailing closure: ErrorStateView(message: error) { ... }
    init(message: String, action: @escaping () -> Void) {
        self.title = "Bir Hata Oluştu"
        self.message = message
        self.buttonTitle = "Tekrar Dene"
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Constants.spacingL) {
            ZStack {
                Circle()
                    .fill(Color.themeError.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(Color.themeError)
            }
            
            VStack(spacing: Constants.spacingS) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.themeText)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.paddingXL)
            }
            
            if let act = action {
                Button(action: act) {
                    Text(buttonTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Constants.paddingL)
                        .padding(.vertical, Constants.paddingM)
                        .background(Color.themePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground)
    }
}

// MARK: - Previews
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            SectionHeaderView(title: "Rozetler", subtitle: "Farklı rozet tipleri", actionTitle: "Tümünü Gör") {}
            
            HStack {
                BadgeView(text: "Varsayılan", style: .success)
                BadgeView(text: "Verified", style: .primary)
                BadgeView(text: "Pending", style: .warning)
            }
            
            SectionHeaderView(title: "Avatar Görünümü", subtitle: "Düzenlenebilir profil resmi")
            
            HStack(spacing: 20) {
                AvatarView(imageURLString: nil, size: 70, isEditable: true) {}
                AvatarView(imageURLString: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150", size: 70, isEditable: false)
            }
            
            SectionHeaderView(title: "İstatistikler", subtitle: "Örnek veri kartları")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(title: "Bugünün Kazancı", value: "₺1,500.00", changeText: "+12.4%", iconName: "turkishlirasign.circle", color: Color.themeSuccess)
                StatCard(title: "Toplam İş", value: "48", changeText: nil, iconName: "briefcase", color: Color.themePrimary)
            }
        }
        .padding()
    }
    .background(Color.themeBackground)
}
