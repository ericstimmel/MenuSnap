//
//  MenuScanResultView.swift
//  MenuSnap
//
//  Created by Eric Stimmel on 1/10/26.
//

import SwiftUI
import UIKit

struct MenuScanResultView: View {
    let image: UIImage
    @State private var viewModel = MenuAnalysisViewModel()
    @State private var showFullImage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Captured Menu Image (tappable to expand)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                    .padding(.horizontal)
                    .onTapGesture {
                        showFullImage = true
                    }

                // Health Rankings Section
                VStack(spacing: 16) {
                    HStack {
                        Text("Health Rankings")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        if viewModel.state == .success {
                            Text("\(viewModel.menuItems.count) items")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Content based on state
                    switch viewModel.state {
                    case .idle, .loading:
                        LoadingView()
                    case .success:
                        MenuItemsList(items: viewModel.menuItems)
                    case .error:
                        ErrorView(message: viewModel.errorMessage ?? "Unknown error") {
                            Task {
                                await viewModel.retry(image: image)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Menu Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.analyzeMenu(image: image)
        }
        .sheet(isPresented: $showFullImage) {
            FullImageView(image: image)
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()

            Text("Analyzing menu...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Reading items and calculating health scores")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("Analysis Failed")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Menu Items List
struct MenuItemsList: View {
    let items: [MenuItem]

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(items) { item in
                MenuItemRow(item: item)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Menu Item Row
struct MenuItemRow: View {
    let item: MenuItem
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(alignment: .top, spacing: 12) {
                // Health Score Badge
                HealthScoreBadge(score: item.healthScore, category: item.healthCategory)

                // Item details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(2)

                    if let description = item.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                }

                Spacer()

                // Expand button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
            }

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Health reason
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text(item.healthReason)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Calories if available
                    if let calories = item.calories, !calories.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "flame")
                                .foregroundStyle(.orange)
                            Text(calories)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
}

// MARK: - Health Score Badge
struct HealthScoreBadge: View {
    let score: Int
    let category: HealthCategory

    var color: Color {
        switch category {
        case .healthy:
            return .green
        case .moderate:
            return .yellow
        case .lessHealthy:
            return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 50, height: 50)

            Circle()
                .strokeBorder(color, lineWidth: 3)
                .frame(width: 50, height: 50)

            Text("\(score)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Full Image View
struct FullImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .navigationTitle("Menu Photo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    NavigationStack {
        MenuScanResultView(image: UIImage(systemName: "photo")!)
    }
}
