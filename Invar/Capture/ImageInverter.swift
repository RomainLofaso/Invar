//
//  ImageInverter.swift
//  Invar
//

import CoreGraphics
import CoreImage

final class ImageInverter {
    private let context = CIContext(options: nil)
    private let settingsQueue = DispatchQueue(label: "Invar.inversionSettings")
    private var settings = InversionSettings.current

    func updateSettings(_ settings: InversionSettings) {
        settingsQueue.sync {
            self.settings = settings
        }
    }

    func invert(_ image: CGImage) -> CGImage? {
        let settings = settingsQueue.sync { self.settings }
        let input = CIImage(cgImage: image)
        guard let filter = CIFilter(name: "CIColorInvert") else {
            return nil
        }
        filter.setValue(input, forKey: kCIInputImageKey)
        guard var output = filter.outputImage else {
            return nil
        }

        if let controls = CIFilter(name: "CIColorControls") {
            controls.setValue(output, forKey: kCIInputImageKey)
            controls.setValue(settings.contrast, forKey: kCIInputContrastKey)
            controls.setValue(settings.brightness, forKey: kCIInputBrightnessKey)
            if let adjusted = controls.outputImage {
                output = adjusted
            }
        }

        if let gamma = CIFilter(name: "CIGammaAdjust") {
            gamma.setValue(output, forKey: kCIInputImageKey)
            gamma.setValue(settings.gamma, forKey: "inputPower")
            if let adjusted = gamma.outputImage {
                output = adjusted
            }
        }

        return context.createCGImage(output, from: output.extent)
    }
}
