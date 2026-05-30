import SwiftUI
import UIKit

// ============================================================
//  PhotoPreviewView.swift
//  멤버 2 — Report Form & Camera
//
//  사진 1장 워크플로우용 UI 모음.
//   - PhotoCapturePlaceholder: 사진 없을 때 점선 촬영 영역
//   - PhotoPreviewView:        촬영된 사진 1장 미리보기 + 삭제/재촬영
// ============================================================

// MARK: - 촬영 영역 플레이스홀더 (사진 없을 때)
/// 디자인 가이드: 점선 테두리 + 카메라 아이콘 + "Tap to take a photo"
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

// MARK: - 촬영된 사진 1장 미리보기
/// 사진이 있을 때 큰 미리보기 + 우상단 삭제(x) + 우하단 재촬영 버튼.
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

            // 삭제 버튼
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.45)))
            }
            .padding(8)

            // 재촬영 버튼 (우하단)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: onRetake) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                            Text("다시 촬영")
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
