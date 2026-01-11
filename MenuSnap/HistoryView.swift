//
//  HistoryView.swift
//  MenuSnap
//
//  Created by Eric Stimmel on 1/10/26.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MenuScan.scanDate, order: .reverse) private var scans: [MenuScan]

    var body: some View {
        Group {
            if scans.isEmpty {
                EmptyHistoryView()
            } else {
                List {
                    ForEach(scans) { scan in
                        NavigationLink(destination: HistoryScanDetailView(scan: scan)) {
                            ScanRowView(scan: scan)
                        }
                    }
                    .onDelete(perform: deleteScans)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History")
        .toolbar {
            if !scans.isEmpty {
                EditButton()
            }
        }
    }

    private func deleteScans(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(scans[index])
            }
        }
    }
}

// MARK: - Empty State
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Saved Scans")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Scan a menu and tap Save to keep it here")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Scan Row
struct ScanRowView: View {
    let scan: MenuScan

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let image = scan.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(scan.restaurantName)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(scan.formattedDate) • \(scan.menuItems.count) items")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: MenuScan.self, inMemory: true)
}
