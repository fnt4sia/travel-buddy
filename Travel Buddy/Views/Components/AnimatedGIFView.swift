import ImageIO
import SwiftUI
import UIKit

struct AnimatedGIFView: UIViewRepresentable {
    let assetName: String
    var repeatCount: Int = 0

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }

    func updateUIView(_ imageView: UIImageView, context: Context) {
        guard context.coordinator.configuredAssetName != assetName
                || context.coordinator.configuredRepeatCount != repeatCount else {
            if context.coordinator.hasFinishedFiniteAnimation {
                imageView.stopAnimating()
                imageView.image = context.coordinator.finalImage
                return
            }

            if !imageView.isAnimating {
                imageView.startAnimating()
            }
            return
        }

        context.coordinator.configuredAssetName = assetName
        context.coordinator.configuredRepeatCount = repeatCount
        context.coordinator.hasFinishedFiniteAnimation = false
        configure(imageView, coordinator: context.coordinator)
    }

    private func configure(_ imageView: UIImageView, coordinator: Coordinator) {
        guard let asset = NSDataAsset(name: assetName) else {
            imageView.image = UIImage(named: assetName)
            return
        }

        guard let animation = GIFAnimation(data: asset.data) else {
            imageView.image = UIImage(data: asset.data)
            return
        }

        imageView.image = animation.frames.first
        imageView.animationImages = animation.frames
        imageView.animationDuration = animation.duration
        imageView.animationRepeatCount = repeatCount
        imageView.startAnimating()

        coordinator.finalImage = animation.frames.last
        coordinator.finishWorkItem?.cancel()

        if repeatCount > 0 {
            let workItem = DispatchWorkItem { [weak imageView, weak coordinator] in
                coordinator?.hasFinishedFiniteAnimation = true
                imageView?.stopAnimating()
                imageView?.image = coordinator?.finalImage
            }
            coordinator.finishWorkItem = workItem
            DispatchQueue.main.asyncAfter(
                deadline: .now() + animation.duration * Double(repeatCount),
                execute: workItem
            )
        }
    }

    final class Coordinator {
        var configuredAssetName: String?
        var configuredRepeatCount: Int?
        var finalImage: UIImage?
        var finishWorkItem: DispatchWorkItem?
        var hasFinishedFiniteAnimation = false
    }
}

private struct GIFAnimation {
    let frames: [UIImage]
    let duration: TimeInterval

    init?(data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else { return nil }

        var decodedFrames: [UIImage] = []
        var totalDuration: TimeInterval = 0

        for index in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }

            decodedFrames.append(UIImage(cgImage: cgImage))
            totalDuration += Self.frameDelay(source: source, index: index)
        }

        guard !decodedFrames.isEmpty else { return nil }

        frames = decodedFrames
        duration = totalDuration > 0 ? totalDuration : TimeInterval(decodedFrames.count) * 0.08
    }

    private static func frameDelay(source: CGImageSource, index: Int) -> TimeInterval {
        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
            let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else {
            return 0.08
        }

        let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let clampedDelay = gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval
        let delay = unclampedDelay ?? clampedDelay ?? 0.08

        return delay < 0.02 ? 0.08 : delay
    }
}
