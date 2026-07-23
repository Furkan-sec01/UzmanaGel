import SwiftUI
import MapKit
struct FilterSheet: View {

    @Binding var filter: ServiceFilter
    let categories: [String]
    @ObservedObject var locationManager: LocationManager
    let onApply: () -> Void
    @ObservedObject private var langManager = LanguageManager.shared

    /// Tüm Türkiye şehirleri (turkishCities verisinden)
    private var allCityNames: [String] {
        turkishCities.map(\.name)
    }

    @State private var minPriceText: String = ""
    @State private var maxPriceText: String = ""
    @State private var isAdvancedExpanded = false

    @Environment(\.dismiss) private var dismiss
    
    private var advancedFilterCount: Int {
        var count = 0
        if filter.minExperienceYears > 0 { count += 1 }
        if filter.minCompletedJobs > 0 { count += 1 }
        if filter.isCertifiedOnly { count += 1 }
        if filter.selectedServiceType != nil { count += 1 }
        return count
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("BackgroundColor").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: - Kategori
                        filterCard {
                            cardHeader(icon: "square.grid.2x2", color: .purple, title: "Kategori".localized)

                            Menu {
                                Button {
                                    filter.selectedCategory = nil
                                } label: {
                                    HStack {
                                        Text("Tüm Kategoriler".localized)
                                        if filter.selectedCategory == nil {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }

                                ForEach(categories, id: \.self) { cat in
                                    Button {
                                        filter.selectedCategory = (filter.selectedCategory == cat) ? nil : cat
                                    } label: {
                                        HStack {
                                            Text(cat.localized)
                                            if filter.selectedCategory == cat {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)

                                    Text((filter.selectedCategory != nil ? filter.selectedCategory!.localized : "Tüm Kategoriler".localized))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(filter.selectedCategory != nil ? .primary : .secondary)

                                    Spacer()

                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }

                        // MARK: - Şehir
                        filterCard {
                            cardHeader(icon: "mappin.and.ellipse", color: .orange, title: "Şehir".localized)

                            Menu {
                                Button {
                                    filter.selectedCity = nil
                                } label: {
                                    HStack {
                                        Text("Tüm Şehirler".localized)
                                        if filter.selectedCity == nil {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }

                                ForEach(allCityNames, id: \.self) { city in
                                    Button {
                                        filter.selectedCity = (filter.selectedCity == city) ? nil : city
                                    } label: {
                                        HStack {
                                            Text(city)
                                            if filter.selectedCity == city {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "building.2")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)

                                    Text(filter.selectedCity ?? "Tüm Şehirler".localized)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(filter.selectedCity != nil ? .primary : .secondary)

                                    Spacer()

                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }

                        // MARK: - Fiyat Aralığı
                        filterCard {
                            cardHeader(icon: "turkishlirasign.circle", color: .green, title: "Fiyat Aralığı".localized)

                            HStack(spacing: 10) {
                                priceField(placeholder: "Min", text: $minPriceText)

                                ZStack {
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(width: 16, height: 1.5)
                                }

                                priceField(placeholder: "Max", text: $maxPriceText)
                            }
                        }

                        // MARK: - Mesafe Seçimi
                        filterCard {
                            cardHeader(icon: "location.circle", color: .red, title: "Mesafe (km)".localized)
                            
                            VStack(spacing: 12) {
                                let distanceOptions: [Double?] = [nil, 5, 10, 20, 50]
                                HStack(spacing: 8) {
                                    ForEach(Array(distanceOptions.enumerated()), id: \.offset) { _, opt in
                                        Button {
                                            triggerHaptic()
                                            filter.maxDistanceKm = opt
                                        } label: {
                                            Text(opt == nil ? "Tümü".localized : "\(Int(opt!)) km")
                                                .font(.system(size: 13, weight: filter.maxDistanceKm == opt ? .bold : .medium))
                                                .padding(.vertical, 8)
                                                .frame(maxWidth: .infinity)
                                                .background(
                                                    filter.maxDistanceKm == opt ? Color.red : Color(.secondarySystemBackground)
                                                )
                                                .foregroundColor(filter.maxDistanceKm == opt ? .white : .primary)
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                if let loc = locationManager.coordinate, let maxDist = filter.maxDistanceKm {
                                    Map(initialPosition: .region(MKCoordinateRegion(
                                        center: loc,
                                        latitudinalMeters: maxDist * 2500,
                                        longitudinalMeters: maxDist * 2500
                                    ))) {
                                        Annotation("Konumum".localized, coordinate: loc) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 24, height: 24)
                                                Image(systemName: "location.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        MapCircle(center: loc, radius: maxDist * 1000)
                                            .foregroundStyle(.blue.opacity(0.15))
                                            .stroke(.blue.opacity(0.8), lineWidth: 2)
                                    }
                                    .frame(height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                                    .padding(.top, 4)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                    .animation(.spring(), value: filter.maxDistanceKm)
                                }
                            }
                        }

                        // MARK: - Müsaitlik Filtresi
                        filterCard {
                            cardHeader(icon: "calendar.badge.clock", color: .cyan, title: "Müsaitlik".localized)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Toggle("Bugün Müsait".localized, isOn: $filter.isTodayAvailable)
                                    .font(.system(size: 13, weight: .medium))
                                    .onChange(of: filter.isTodayAvailable) { _ in triggerHaptic() }
                                
                                Toggle("Bu Hafta Müsait".localized, isOn: $filter.isThisWeekAvailable)
                                    .font(.system(size: 13, weight: .medium))
                                    .onChange(of: filter.isThisWeekAvailable) { _ in triggerHaptic() }
                                
                                Divider().padding(.vertical, 2)
                                
                                HStack {
                                    Text("Belirli Bir Tarih".localized)
                                        .font(.system(size: 13, weight: .medium))
                                    Spacer()
                                    if filter.selectedDate != nil {
                                        Button(action: { filter.selectedDate = nil }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    DatePicker("", selection: Binding(
                                        get: { filter.selectedDate ?? Date() },
                                        set: { filter.selectedDate = $0 }
                                    ), displayedComponents: .date)
                                    .labelsHidden()
                                }
                                
                                HStack {
                                    Text("Saat Aralığı".localized)
                                        .font(.system(size: 13, weight: .medium))
                                    Spacer()
                                    if filter.startTime != nil || filter.endTime != nil {
                                        Button(action: { 
                                            filter.startTime = nil
                                            filter.endTime = nil
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    HStack(spacing: 2) {
                                        DatePicker("Başlangıç", selection: Binding(
                                            get: { filter.startTime ?? Date() },
                                            set: { filter.startTime = $0 }
                                        ), displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        
                                        Text("-").foregroundColor(.secondary)
                                        
                                        DatePicker("Bitiş", selection: Binding(
                                            get: { filter.endTime ?? Date() },
                                            set: { filter.endTime = $0 }
                                        ), displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                    }
                                }
                            }
                        }

                        // MARK: - Sıralama
                        filterCard {
                            cardHeader(icon: "arrow.up.arrow.down", color: .blue, title: "Sıralama".localized)

                            VStack(spacing: 0) {
                                ForEach(Array(ServiceFilter.SortOption.allCases.enumerated()), id: \.element) { index, option in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            filter.sortOption = option
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .stroke(
                                                        filter.sortOption == option
                                                            ? Color("PrimaryColor")
                                                            : Color(.separator),
                                                        lineWidth: 2
                                                    )
                                                    .frame(width: 20, height: 20)

                                                if filter.sortOption == option {
                                                    Circle()
                                                        .fill(Color("PrimaryColor"))
                                                        .frame(width: 10, height: 10)
                                                }
                                            }

                                            Text(option.rawValue.localized)
                                                .font(.system(size: 14, weight: filter.sortOption == option ? .semibold : .regular))
                                                .foregroundColor(.primary)

                                            Spacer()

                                            if option != .none {
                                                Image(systemName: option == .priceLowToHigh ? "arrow.up.right" : "arrow.down.right")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(filter.sortOption == option ? Color("PrimaryColor") : .secondary)
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 4)
                                    }
                                    .buttonStyle(.plain)

                                    if index < ServiceFilter.SortOption.allCases.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }

                        // MARK: - Değerlendirme Filtresi (Star Rating Selector)
                        filterCard {
                            cardHeader(icon: "star.fill", color: .yellow, title: "Minimum Değerlendirme".localized)

                            VStack(spacing: 14) {
                                let ratingOptions: [Double?] = [nil, 4.0, 4.5, 5.0]
                                HStack(spacing: 8) {
                                    ForEach(Array(ratingOptions.enumerated()), id: \.offset) { _, opt in
                                        Button {
                                            triggerHaptic()
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                                filter.minRating = opt
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                if let val = opt {
                                                    Image(systemName: "star.fill")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(filter.minRating == opt ? .white : .orange)
                                                    Text(String(format: "%.1f+", val))
                                                } else {
                                                    Text("Tümü".localized)
                                                }
                                            }
                                            .font(.system(size: 13, weight: filter.minRating == opt ? .bold : .medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                filter.minRating == opt ? Color("PrimaryColor") : Color(.secondarySystemBackground)
                                            )
                                            .foregroundColor(filter.minRating == opt ? .white : .primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                // Interactive star display
                                HStack(spacing: 6) {
                                    Text("Hızlı Seçim:".localized)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    ForEach(1...5, id: \.self) { star in
                                        Button {
                                            triggerHaptic()
                                            filter.minRating = Double(star)
                                        } label: {
                                            Image(systemName: Double(star) <= (filter.minRating ?? 0) ? "star.fill" : "star")
                                                .font(.system(size: 18))
                                                .foregroundColor(.orange)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }

                        // MARK: - Gelişmiş Filtreler Accordion (DisclosureGroup)
                        filterCard {
                            DisclosureGroup(isExpanded: $isAdvancedExpanded) {
                                VStack(alignment: .leading, spacing: 18) {
                                    
                                    // 1. Deneyim Yılı (Stepper)
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Deneyim Yılı".localized)
                                                .font(.system(size: 14, weight: .semibold))
                                            Text(filter.minExperienceYears > 0 ? "\(filter.minExperienceYears)+ Yıl Deneyim".localized : "Fark etmez".localized)
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Stepper("", value: $filter.minExperienceYears, in: 0...50, step: 1)
                                            .labelsHidden()
                                            .onChange(of: filter.minExperienceYears) { _ in
                                                triggerHaptic()
                                            }
                                    }
                                    Divider()

                                    // 2. Tamamlanan İş Sayısı (Stepper)
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Tamamlanan İş Sayısı".localized)
                                                .font(.system(size: 14, weight: .semibold))
                                            Text(filter.minCompletedJobs > 0 ? "En az \(filter.minCompletedJobs) iş".localized : "Fark etmez".localized)
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Stepper("", value: $filter.minCompletedJobs, in: 0...500, step: 5)
                                            .labelsHidden()
                                            .onChange(of: filter.minCompletedJobs) { _ in
                                                triggerHaptic()
                                            }
                                    }
                                    Divider()

                                    // 3. Sadece Sertifikalılar (Toggle)
                                    Toggle(isOn: $filter.isCertifiedOnly) {
                                        Text("Sadece Sertifikalı Uzmanlar".localized)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .onChange(of: filter.isCertifiedOnly) { _ in triggerHaptic() }
                                    Divider()

                                    // 4. Hizmet Türü (Segmented)
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Hizmet Sağlayıcı Türü".localized)
                                            .font(.system(size: 14, weight: .semibold))
                                        
                                        Picker("Tür", selection: Binding(
                                            get: { filter.selectedServiceType ?? "Tümü" },
                                            set: { val in
                                                triggerHaptic()
                                                filter.selectedServiceType = (val == "Tümü" ? nil : val)
                                            }
                                        )) {
                                            Text("Tümü".localized).tag("Tümü")
                                            Text("Şahıs".localized).tag("sahis")
                                            Text("Şirket".localized).tag("sirket")
                                        }
                                        .pickerStyle(.segmented)
                                    }
                                }
                                .padding(.top, 14)
                            } label: {
                                HStack {
                                    cardHeader(icon: "slider.horizontal.3", color: .purple, title: "Gelişmiş Filtreler".localized)
                                    Spacer()
                                    let advCount = advancedFilterCount
                                    if advCount > 0 {
                                        Text("\(advCount)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.purple)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // MARK: - Alt Butonlar
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 12) {
                        Button {
                            filter.reset()
                            minPriceText = ""
                            maxPriceText = ""
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Sıfırla".localized)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button {
                            filter.minPrice = Int(minPriceText)
                            filter.maxPrice = Int(maxPriceText)
                            onApply()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Uygula".localized)
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("PrimaryColor"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Filtrele & Sırala".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                minPriceText = filter.minPrice.map { String($0) } ?? ""
                maxPriceText = filter.maxPrice.map { String($0) } ?? ""
            }
        }
    }

    // MARK: - Components

    private func filterCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(16)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func cardHeader(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
    }

    private func triggerHaptic() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    private func priceField(placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 6) {
            Text("₺")
                .foregroundColor(.secondary)
                .font(.system(size: 14, weight: .semibold))
            
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
