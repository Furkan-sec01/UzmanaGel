import SwiftUI
import MapKit
import FirebaseFirestore

struct ServiceDetailPage: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: ServiceDetailViewModel

    init(service: Service, imageURL: URL?, isFavorite: Bool) {
        _vm = StateObject(wrappedValue: ServiceDetailViewModel(
            service: service,
            imageURL: imageURL,
            isFavorite: isFavorite
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("BackgroundColor").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    contentSection
                }
            }

            ctaButton
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color("PrimaryColor"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .task { vm.load() }
    }
}

// MARK: - Header + Profile Card

private extension ServiceDetailPage {

    var headerSection: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Color("PrimaryColor")
                    .frame(height: 120)
                Color.clear
                    .frame(height: 70)
            }

            profileCard
                .padding(.horizontal, 20)
        }
    }

    var profileCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                profileAvatar
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.service.providerName.isEmpty
                         ? vm.service.title
                         : vm.service.providerName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("Text"))
                        .lineLimit(1)

                    Text(vm.service.category)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button { vm.toggleFavorite() } label: {
                    Image(systemName: vm.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)

                Text(String(format: "%.1f", vm.service.rating))
                    .font(.system(size: 14, weight: .semibold))

                Text("(0 yorum)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary)

                Button("Yorumları Gör") { }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color("PrimaryColor"))

                Spacer()
            }
        }
        .padding(18)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    var profileAvatar: some View {
        Group {
            if let url = vm.coverImageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
    }

    var avatarPlaceholder: some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(systemName: "person.circle.fill")
                .font(.system(size: 34))
                .foregroundColor(.secondary.opacity(0.5))
        }
    }
}

// MARK: - Content

private extension ServiceDetailPage {

    var contentSection: some View {
        VStack(spacing: 24) {
            statsRow
            sectionDivider
            aboutSection
            sectionDivider
            servicesSection
            sectionDivider
            gallerySection
            sectionDivider
            workingHoursSection
            sectionDivider
            locationSection
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 100)
    }

    var sectionDivider: some View {
        Divider().padding(.horizontal, 4)
    }
}

// MARK: - Stats Row

private extension ServiceDetailPage {

    var statsRow: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "checkmark.seal.fill",
                iconColor: .green,
                value: "\(vm.service.experienceYears) Yıl",
                label: "Deneyim"
            )
            statCard(
                icon: "checkmark.seal.fill",
                iconColor: .green,
                value: "0",
                label: "İş Tamamlandı"
            )
            statCard(
                icon: "clock",
                iconColor: .secondary,
                value: "Hemen",
                label: "Yanıt Süresi"
            )
        }
    }

    func statCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color("Text"))

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

// MARK: - About

private extension ServiceDetailPage {

    var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hakkında")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("Text"))

            Text(vm.service.description.isEmpty
                 ? "Bu hizmet sağlayıcı henüz detaylı bir açıklama girmemiş."
                 : vm.service.description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Services & Pricing

private extension ServiceDetailPage {

    var servicesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Hizmetler & Fiyatlar")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("Text"))

            if vm.providerServices.isEmpty && !vm.isLoading {
                serviceRow(title: vm.service.title,
                           duration: vm.service.duration,
                           price: vm.service.price)
            } else {
                ForEach(vm.providerServices) { svc in
                    serviceRow(title: svc.title,
                               duration: svc.duration,
                               price: svc.price)

                    if svc.id != vm.providerServices.last?.id {
                        Divider().padding(.leading, 4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func serviceRow(title: String, duration: String, price: Int) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("TertiaryColor"))

                if !duration.isEmpty {
                    Text(duration)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("₺\(price)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("Text"))
                Text("başlangıç fiyatı")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Gallery

private extension ServiceDetailPage {

    var gallerySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Portföy / Galeri")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("Text"))

            if vm.galleryURLs.isEmpty {
                Text("Henüz portföy görseli eklenmemiş.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(vm.galleryURLs, id: \.absoluteString) { url in
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable().scaledToFill()
                                default:
                                    Color(.secondarySystemBackground)
                                        .overlay(ProgressView())
                                }
                            }
                            .frame(width: 140, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Working Hours

private extension ServiceDetailPage {

    var workingHoursSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Çalışma Saatleri")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("Text"))

            VStack(spacing: 12) {
                if !vm.workingDaysDisplayNames.isEmpty || vm.workingHoursRangeText != nil {
                    if let rangeText = vm.workingHoursRangeText, !rangeText.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "clock")
                                .font(.system(size: 18))
                                .foregroundColor(Color("PrimaryColor"))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(rangeText)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color("Text"))
                                if !vm.workingDaysDisplayNames.isEmpty {
                                    Text(vm.workingDaysDisplayNames.joined(separator: ", "))
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                    if !vm.workingDaysDisplayNames.isEmpty && vm.workingHoursRangeText == nil {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 18))
                                .foregroundColor(Color("PrimaryColor"))
                                .frame(width: 24)
                            Text(vm.workingDaysDisplayNames.joined(separator: ", "))
                                .font(.system(size: 14))
                                .foregroundColor(Color("Text"))
                            Spacer()
                        }
                    }
                    let closedDays = closedDaysText
                    if !closedDays.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text(closedDays)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        Text("Çalışma saatleri henüz girilmemiş.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Kapalı günleri metin olarak döndürür (çalışılmayan günler). Sıra: Pzt→Paz.
    private var closedDaysText: String {
        let order = ["1", "2", "3", "4", "5", "6", "7"]
        let names = ["1": "Pazartesi", "2": "Salı", "3": "Çarşamba", "4": "Perşembe", "5": "Cuma", "6": "Cumartesi", "7": "Pazar"]
        let working = Set(vm.expertProfile?.workingDays ?? [])
        let closed = order.filter { !working.contains($0) }.compactMap { names[$0] }
        if closed.isEmpty { return "" }
        return "Kapalı: \(closed.joined(separator: ", "))"
    }
}

// MARK: - Location

private extension ServiceDetailPage {

    var locationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Konum")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("Text"))

            if let geo = vm.service.locationGeo {
                let coordinate = CLLocationCoordinate2D(
                    latitude: geo.latitude,
                    longitude: geo.longitude
                )

                Button {
                    vm.openDirections()
                } label: {
                    mapView(coordinate: coordinate)
                }
                .buttonStyle(.plain)

                Button {
                    vm.openDirections()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                        Text(vm.addressText.isEmpty ? vm.service.city : vm.addressText)
                            .font(.system(size: 14))
                            .foregroundColor(Color("Text"))
                        Spacer()
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
                .buttonStyle(.plain)
            } else if !vm.service.city.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                    Text(vm.service.city)
                        .font(.system(size: 14))
                        .foregroundColor(Color("Text"))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func mapView(coordinate: CLLocationCoordinate2D) -> some View {
        ZStack(alignment: .bottom) {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
            ))) {
                Marker(vm.service.providerName.isEmpty
                       ? vm.service.title
                       : vm.service.providerName,
                       coordinate: coordinate)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .allowsHitTesting(false)

            Button {
                vm.openDirections()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Yol Tarifi Al")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Color("Text"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .padding(.bottom, 12)
        }
    }
}

// MARK: - CTA Button

private extension ServiceDetailPage {

    var ctaButton: some View {
        Button { } label: {
            Text("Yardım Al")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("PrimaryColor"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [Color("BackgroundColor"), Color("BackgroundColor").opacity(0.95)],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}
