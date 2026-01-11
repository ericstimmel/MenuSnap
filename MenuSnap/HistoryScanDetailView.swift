//
//  HistoryScanDetailView.swift
//  MenuSnap
//
//  Created by Eric Stimmel on 1/10/26.
//

import SwiftUI
import SwiftData

struct HistoryScanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let scan: MenuScan
    @State private var showFullImage = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Menu Image
                if let image = scan.image {
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
                }

                // Scan Info
                VStack(spacing: 8) {
                    Text(scan.restaurantName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(scan.formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Health Rankings
                VStack(spacing: 16) {
                    HStack {
                        Text("Health Rankings")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(scan.menuItems.count) items")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    if scan.menuItems.isEmpty {
                        Text("No menu items saved")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(scan.menuItems) { item in
                                MenuItemRow(item: item)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Scan Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showFullImage) {
            if let image = scan.image {
                FullImageView(image: image)
            }
        }
        .confirmationDialog("Delete this scan?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(scan)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    NavigationStack {
        HistoryScanDetailView(scan: MenuScan(
            restaurantName: "Sample Restaurant",
            image: UIImage(systemName: "photo")!,
            menuItems: []
        ))
    }
    .modelContainer(for: MenuScan.self, inMemory: true)
}
