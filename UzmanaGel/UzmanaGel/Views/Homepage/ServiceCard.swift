//
//  ServiceCard.swift
//  UzmanaGel
//
//  Created by Abdullah B on 5.02.2026.
//

import SwiftUI

struct ServiceCard: View {

    let service: Service
    var distanceText: String?
    var imageURL: URL?

    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {

            ZStack(alignment: .bottomLeading) {
                serviceImage
                    .frame(width: 74, height: 74)
                    .clipShape(Circle())

                Circle()
                    .fill(service.isAvailable ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: 6, y: -6)
            }
            .frame(width: 74, height: 74)

            VStack(alignment: .leading, spacing: 6) {

                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(service.providerName.isEmpty ? service.title : service.providerName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        if !service.providerName.isEmpty && !service.title.isEmpty {
                            Text(service.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Button {
                        onToggleFavorite()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)

                        Text(String(format: "%.1f", service.rating))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text("(0 yorum)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text(service.city)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        if let distanceText {
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)

                            Text(distanceText)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color("PrimaryColor"))
                        }
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text(service.category)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()
                }

                HStack {
                    Spacer()

                    Text("₺\(service.price)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color("TertiaryColor"))

                    Text("başlangıç fiyatı")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.15),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    private var serviceImage: some View {
        Group {
            if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .empty:
                        ZStack {
                            Color(.secondarySystemBackground)
                            ProgressView()
                        }
                    default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
    }

    private var imagePlaceholder: some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(systemName: "person.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.secondary.opacity(0.5))
        }
    }
}
