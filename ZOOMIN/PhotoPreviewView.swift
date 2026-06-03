import SwiftUI
import UIKit

// ============================================================
//  PhotoPreviewView.swift
//  Member 2 — Report Form & Camera
//
//  UI components for single-photo workflow.
//   - PhotoCapturePlaceholder: dashed capture area when no photo
//   - PhotoPreviewView: preview of captured photo + delete/retake
// ============================================================

// MARK: - Capture Area Placeholder (no photo)
/// Design guide: dashed border + camera icon + "Tap to take a photo"
struct PhotoCapturePlaceholder: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.zoominBlue)
                Text("Tap to take a photo")
                    .font(ZOOMINFont.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(Color.surfaceTertiary)
            .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    .foregroundColor(Color.zoominBlue.opacity(0.4))
            )
        }
    }
}

// MARK: - Single Photo Preview
/// Full preview with delete (x) top-right and retake button bottom-right.
struct PhotoPreviewView: View {
    let image: UIImage
    var onRemove: () -> Void
    var onRetake: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge)
                        .stroke(Color.zoominBlue.opacity(0.2), lineWidth: 1)
                )

            // Delete button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.45)))
            }
            .padding(8)

            // Retake button (bottom-right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: onRetake) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                            Text("Retake")
                                .font(ZOOMINFont.captionBold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Capsule())
                    }
                    .padding(8)
                }
            }
        }
    }
}
