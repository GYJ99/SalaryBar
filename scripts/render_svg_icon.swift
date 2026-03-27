import AppKit
import Foundation
import QuickLookThumbnailing

enum RenderSVGIconError: Error, CustomStringConvertible {
    case invalidArguments
    case invalidSize(String)
    case missingRepresentation
    case failedToEncodePNG

    var description: String {
        switch self {
        case .invalidArguments:
            return "usage: swift scripts/render_svg_icon.swift <input.svg> <output.png> <size>"
        case let .invalidSize(value):
            return "invalid size: \(value)"
        case .missingRepresentation:
            return "Quick Look did not return a thumbnail representation"
        case .failedToEncodePNG:
            return "failed to encode thumbnail as PNG"
        }
    }
}

let args = CommandLine.arguments
guard args.count == 4 else {
    throw RenderSVGIconError.invalidArguments
}

let inputURL = URL(fileURLWithPath: args[1])
let outputURL = URL(fileURLWithPath: args[2])
guard let sizeValue = Double(args[3]), sizeValue > 0 else {
    throw RenderSVGIconError.invalidSize(args[3])
}

let request = QLThumbnailGenerator.Request(
    fileAt: inputURL,
    size: CGSize(width: sizeValue, height: sizeValue),
    scale: 1,
    representationTypes: .thumbnail
)

let semaphore = DispatchSemaphore(value: 0)
var renderError: Error?

QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, error in
    defer { semaphore.signal() }

    if let error {
        renderError = error
        return
    }

    guard let representation else {
        renderError = RenderSVGIconError.missingRepresentation
        return
    }

    let bitmap = NSBitmapImageRep(cgImage: representation.cgImage)
    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        renderError = RenderSVGIconError.failedToEncodePNG
        return
    }

    do {
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try pngData.write(to: outputURL)
    } catch {
        renderError = error
    }
}

semaphore.wait()

if let renderError {
    throw renderError
}
