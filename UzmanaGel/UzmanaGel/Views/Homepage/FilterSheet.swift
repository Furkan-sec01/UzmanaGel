import SwiftUI

struct FilterSheet: View {

    @Binding var filter: ServiceFilter
    let categories: [String]
    let onApply: () -> Void

    /// Tüm Türkiye şehirleri (turkishCities verisinden)
    private var allCityNames: [String] {
        turkishCities.map(\.name)
    }

    @State private var minPriceText: String = ""
    @State private var maxPriceText: String = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("BackgroundColor").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: - Kategori
                        filterCard {
                            cardHeader(icon: "square.grid.2x2", color: .purple, title: "Kategori")

                            Menu {
                                Button {
                                    filter.selectedCategory = nil
                                } label: {
                                    HStack {
                                        Text("Tüm Kategoriler")
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
                                            Text(cat)
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

                                    Text(filter.selectedCategory ?? "Tüm Kategoriler")
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
                            cardHeader(icon: "mappin.and.ellipse", color: .orange, title: "Şehir")

                            Menu {
                                Button {
                                    filter.selectedCity = nil
                                } label: {
                                    HStack {
                                        Text("Tüm Şehirler")
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

                                    Text(filter.selectedCity ?? "Tüm Şehirler")
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
                            cardHeader(icon: "turkishlirasign.circle", color: .green, title: "Fiyat Aralığı")

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

                        // MARK: - Sıralama
                        filterCard {
                            cardHeader(icon: "arrow.up.arrow.down", color: .blue, title: "Sıralama")

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

                                            Text(option.rawValue)
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
                                Text("Sıfırla")
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
                                Text("Uygula")
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
            .navigationTitle("Filtrele & Sırala")
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

    private func chipButton(title: String, icon: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? Color("PrimaryColor") : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color(.separator).opacity(0.5), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func priceField(placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 6) {
            Text("₺")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color("PrimaryColor"))
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .keyboardType(.numberPad)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
