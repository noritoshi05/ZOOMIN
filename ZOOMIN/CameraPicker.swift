import SwiftUI
import UIKit
import PhotosUI

// ============================================================
//  CameraPicker.swift
//  멤버 2 — Report Form & Camera
//
//  카메라 촬영 + 앨범 선택 래퍼.
//  IssueStore.addIssue 가 photoData: Data? (사진 1장) 를 받으므로
//  단일 이미지 워크플로우에 맞춰 구성.
//
//  ⚠️ Info.plist 필수 키 (없으면 앱 즉시 크래시):
//    - NSCameraUsageDescription
//    - NSPhotoLibraryUsageDescription
// ============================================================

// MARK: - 카메라 촬영 (UIImagePickerController)
struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        } else {
            // 시뮬레이터 등 카메라 없는 환경 → 앨범으로 폴백
            picker.sourceType = .photoLibrary
        }
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - 앨범에서 선택 (PHPickerViewController) — 1장
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        init(_ parent: PhotoLibraryPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let image = object as? UIImage else { return }
                DispatchQueue.main.async {
                    self.parent.onImagePicked(image)
                }
            }
        }
    }
}

// MARK: - UIImage → Data 변환 헬퍼
extension UIImage {
    /// IssueStore.addIssue 의 photoData 로 넘길 JPEG Data.
    /// 너무 큰 원본을 그대로 저장하지 않도록 다운스케일 + 압축.
    func jpegDataForUpload(maxDimension: CGFloat = 1280, quality: CGFloat = 0.8) -> Data? {
        let scaled = downscaled(maxDimension: maxDimension)
        return scaled.jpegData(compressionQuality: quality)
    }

    private func downscaled(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        let ratio = maxDimension / maxSide
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
