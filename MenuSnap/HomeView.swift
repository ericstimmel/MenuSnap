//
//  HomeView.swift
//  MenuSnap
//
//  Created by Eric Stimmel on 1/10/26.
//

import SwiftUI
import UIKit

struct HomeView: View {
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var capturedImage: UIImage?
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                // App Title and Description
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green)

                    Text("MenuSnap")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Snap a photo of any menu and get instant health rankings for each dish")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Buttons
                VStack(spacing: 16) {
                    // Scan Menu Button (Camera)
                    Button(action: {
                        showCamera = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Scan Menu")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Choose Photo Button
                    Button(action: {
                        showPhotoLibrary = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                            Text("Choose Photo")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: HistoryView()) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $capturedImage, isPresented: $showCamera, sourceType: .camera)
            }
            .sheet(isPresented: $showPhotoLibrary) {
                CameraView(image: $capturedImage, isPresented: $showPhotoLibrary, sourceType: .photoLibrary)
            }
            .onChange(of: capturedImage) { oldValue, newValue in
                if newValue != nil {
                    showResult = true
                }
            }
            .navigationDestination(isPresented: $showResult) {
                if let image = capturedImage {
                    MenuScanResultView(image: image)
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
