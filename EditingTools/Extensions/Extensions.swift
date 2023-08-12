import UIKit
import Vision

extension UIResponder {
    /// Access parent controller
    public var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}

extension UIImageView {

    /// Find the size of the image, once the parent imageView has been given a contentMode of .scaleAspectFit
    /// Querying the image.size returns the non-scaled size. This helper property is needed for accurate results.
    var aspectFitSize: CGSize {
        guard let image = image else { return CGSize.zero }

        var aspectFitSize = CGSize(width: frame.size.width, height: frame.size.height)
        let newWidth: CGFloat = frame.size.width / image.size.width
        let newHeight: CGFloat = frame.size.height / image.size.height

        if newHeight < newWidth {
            aspectFitSize.width = newHeight * image.size.width
        } else if newWidth < newHeight {
            aspectFitSize.height = newWidth * image.size.height
        }

        return aspectFitSize
    }

    /// Find the size of the image, once the parent imageView has been given a contentMode of .scaleAspectFill
    /// Querying the image.size returns the non-scaled, vastly too large size. This helper property is needed for accurate results.
    var aspectFillSize: CGSize {
        guard let image = image else { return CGSize.zero }

        var aspectFillSize = CGSize(width: frame.size.width, height: frame.size.height)
        let newWidth: CGFloat = frame.size.width / image.size.width
        let newHeight: CGFloat = frame.size.height / image.size.height

        if newHeight > newWidth {
            aspectFillSize.width = newHeight * image.size.width
        } else if newWidth > newHeight {
            aspectFillSize.height = newWidth * image.size.height
        }

        return aspectFillSize
    }
}

extension String: Error {}

extension String {
    /// Calculate string height from width and font
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(boundingBox.height)
    }

    /// Calculate string width from height and font
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(boundingBox.width)
    }
}

extension CIImage {
    
    /// Grayscale image
    func convertToGrayScale() throws -> UIImage {
        let filter: CIFilter = CIFilter(name: "CIPhotoEffectMono")!
        filter.setDefaults()
        filter.setValue(self, forKey: kCIInputImageKey)
        
        guard let ciImage = filter.outputImage else {
            throw "Failed to convert image to grayscale"
        }
        
        let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent)
        guard let cgImage = cgImage else {
            throw "Failed to construct grayscale image"
        }
        
        return UIImage(cgImage: cgImage)
    }
    
}

extension UIImage {

    func resizeImageTo(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func withPadding(x: CGFloat, y: CGFloat) -> UIImage? {
        let newWidth = size.width + 2 * x
        let newHeight = size.height + 2 * y
        let newSize = CGSize(width: newWidth, height: newHeight)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        
        let origin = CGPoint(x: (newWidth - size.width) / 2, y: (newHeight - size.height) / 2)
        draw(at: origin)
        
        let imageWithPadding = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithPadding
    }
    
    /// Convert image pixels to black or white pixels via threshold
    /// https://stackoverflow.com/a/31661519
    func convertToBlackAndWhite() -> UIImage? {
        guard let inputCGImage = self.cgImage else {
            print("Unable to get cgImage")
            return nil
        }
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = inputCGImage.width
        let height           = inputCGImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = RGBA32.bitmapInfo
        let threshold        = 44 // components less than 44 of 256 will be considered white, others as black

        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            print("Unable to create context")
            return nil
        }
        context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let buffer = context.data else {
            print("Unable to get context data")
            return nil
        }

        let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: width * height)
        
        for row in 0 ..< Int(height) {
            for column in 0 ..< Int(width) {
                let offset = row * width + column
                if (pixelBuffer[offset].redComponent > threshold &&
                    pixelBuffer[offset].greenComponent > threshold &&
                    pixelBuffer[offset].blueComponent > threshold) {
                    pixelBuffer[offset] = .black
                }
            }
        }

        guard let outputCGImage = context.makeImage() else {
            print("Unable to make an image")
            return nil
        }
        
        return UIImage(cgImage: outputCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
}

/// Structure used by convertToBlackAndWhite()
struct RGBA32: Equatable {
    private var color: UInt32

    var redComponent: UInt8 {
        return UInt8((color >> 24) & 255)
    }

    var greenComponent: UInt8 {
        return UInt8((color >> 16) & 255)
    }

    var blueComponent: UInt8 {
        return UInt8((color >> 8) & 255)
    }

    var alphaComponent: UInt8 {
        return UInt8((color >> 0) & 255)
    }

    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        let red   = UInt32(red)
        let green = UInt32(green)
        let blue  = UInt32(blue)
        let alpha = UInt32(alpha)
        color = (red << 24) | (green << 16) | (blue << 8) | (alpha << 0)
    }

    static let red     = RGBA32(red: 255, green: 0,   blue: 0,   alpha: 255)
    static let green   = RGBA32(red: 0,   green: 255, blue: 0,   alpha: 255)
    static let blue    = RGBA32(red: 0,   green: 0,   blue: 255, alpha: 255)
    static let white   = RGBA32(red: 255, green: 255, blue: 255, alpha: 255)
    static let black   = RGBA32(red: 0,   green: 0,   blue: 0,   alpha: 255)
    static let magenta = RGBA32(red: 255, green: 0,   blue: 255, alpha: 255)
    static let yellow  = RGBA32(red: 255, green: 255, blue: 0,   alpha: 255)
    static let cyan    = RGBA32(red: 0,   green: 255, blue: 255, alpha: 255)

    static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue

    static func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
        return lhs.color == rhs.color
    }
}

import AVKit
import Photos

extension AVAssetTrack {
    var fixedPreferredTransform: CGAffineTransform {
        var t = preferredTransform
        switch(t.a, t.b, t.c, t.d) {
        case (1, 0, 0, 1):
            t.tx = 0
            t.ty = 0
        case (1, 0, 0, -1):
            t.tx = 0
            t.ty = naturalSize.height
        case (-1, 0, 0, 1):
            t.tx = naturalSize.width
            t.ty = 0
        case (-1, 0, 0, -1):
            t.tx = naturalSize.width
            t.ty = naturalSize.height
        case (0, -1, 1, 0):
            t.tx = 0
            t.ty = naturalSize.width
        case (0, 1, -1, 0):
            t.tx = naturalSize.height
            t.ty = 0
        case (0, 1, 1, 0):
            t.tx = 0
            t.ty = 0
        case (0, -1, -1, 0):
            t.tx = naturalSize.height
            t.ty = naturalSize.width
        default:
            break
        }
        
        return t
    }
}

import PencilKit

enum DrawingShape: String {
    /// ML keys used to init
    case ellipsis = "circle", rectangle, triangle, star
}

extension PKDrawing {
    
    /// Create PKDrawing from predefined shapes
    /// `thikness` will be overriden from PKInkingTool if provided
    init(with shape: DrawingShape, in bounds: CGRect, tool: PKInkingTool?, opacity: CGFloat = 1.0, thikness: CGFloat = 3.0) {
        // load thikness from PKInkingTool if available
        var thikness = thikness
        if let tool = tool {
            thikness = max(3.0, tool.width)
        }
        
        switch (shape) {
        case .ellipsis:
            let ink: PKInk = tool?.ink ?? PKInk(.pen, color: UIColor.systemRed)

            let diameter: Double
            var scaleX = 1.0, scaleY = 1.0
            if (bounds.width > bounds.height) {
                diameter = bounds.height
                // scale horizontally
                scaleX = bounds.width / bounds.height
            } else {
                diameter = bounds.width
                // scale vertically
                scaleY = bounds.height / bounds.width
            }
                            
            let radius = diameter / 2.0
            let origin = CGPoint(
                x: bounds.origin.x + bounds.width / 2.0,
                y: bounds.origin.y + bounds.height / 2.0
            )
            
            // draw circle inside the bounds
            var controlPoints: [PKStrokePoint] = []
            controlPoints.reserveCapacity(360)
                            
            var angle = 0.0
            for i in 0...360 {
                angle = Double(i)
                let x = radius * cos(angle * Double.pi / 180) * scaleX
                let y = radius * sin(angle * Double.pi / 180) * scaleY
                let location = CGPoint(x: origin.x + x, y: origin.y + y)
                let point = PKStrokePoint(location: location, timeOffset: 0, size: CGSize(width: thikness, height: thikness), opacity: opacity, force: 0, azimuth: 0, altitude: 0)
                controlPoints.append(point)
            }

            let strokePath = PKStrokePath(controlPoints: controlPoints, creationDate: Date())
            let stroke = PKStroke(ink: ink, path: strokePath)
            self = PKDrawing(strokes: [stroke])
            break
        case .rectangle:
            // draw unfilled rectangle within the bounds at origin
            
            let ink: PKInk = tool?.ink ?? PKInk(.pen, color: UIColor.systemRed)
            let size = CGSize(width: thikness, height: thikness)
            let creationDate = Date()
                                            
            let strokePath1 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: bounds.minX, y: bounds.minY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: bounds.maxX, y: bounds.minY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)
            
            let strokePath2 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: bounds.maxX, y: bounds.minY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: bounds.maxX, y: bounds.maxY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)
            
            let strokePath3 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: bounds.maxX, y: bounds.maxY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: bounds.minX, y: bounds.maxY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)
            
            let strokePath4 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: bounds.minX, y: bounds.maxY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: bounds.minX, y: bounds.minY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)

            self = PKDrawing(strokes: [
                PKStroke(ink: ink, path: strokePath1),
                PKStroke(ink: ink, path: strokePath2),
                PKStroke(ink: ink, path: strokePath3),
                PKStroke(ink: ink, path: strokePath4)
            ])
            break
        case .triangle:
            // draw perfect triangle inside the bounds
            
            let ink: PKInk = tool?.ink ?? PKInk(.pen, color: UIColor.systemRed)
            let size = CGSize(width: thikness, height: thikness)
            let creationDate = Date()
             
            let strokePath1 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: bounds.minX, y: bounds.maxY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: bounds.maxX/2, y: bounds.minY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)
            
            let strokePath2 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: bounds.maxX/2, y: bounds.minY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: bounds.maxX, y: bounds.maxY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)
            
            let strokePath3 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: bounds.maxX, y: bounds.maxY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: bounds.minX, y: bounds.maxY), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)

            self = PKDrawing(strokes: [
                PKStroke(ink: ink, path: strokePath1),
                PKStroke(ink: ink, path: strokePath2),
                PKStroke(ink: ink, path: strokePath3),
            ])
            break
        case .star:
            // draw predefined star inside the bounds
            
            let ink: PKInk = tool?.ink ?? PKInk(.pen, color: UIColor.systemRed)
            let size = CGSize(width: thikness, height: thikness)
            let creationDate = Date()
            
            let lenght = bounds.width > bounds.height ? bounds.width : bounds.height
            
            let multiply = lenght / 3.0 // 3x3 axis used
            
            let x = bounds.origin.x
            let y = bounds.origin.y
            
            let strokePath1 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: 1.5*multiply + x, y: y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: y),
                PKStrokePoint(location: CGPoint(x: 2*multiply + x, y: 1*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: Date())
            
            let strokePath2 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: 2*multiply + x, y: 1*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: 3*multiply + x, y: 1*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)
            
            let strokePath3 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: 3*multiply + x, y: 1*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: 2.125*multiply + x, y: 1.75*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)
            
            let strokePath4 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: 2.125*multiply + x, y: 1.75*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: 2.5*multiply + x, y: 3*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)
            
            let strokePath5 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: 2.5*multiply + x, y: 3*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: 1.5*multiply + x, y: 2.25*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)
            
            let strokePath6 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: 1.5*multiply + x, y: 2.25*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: 0.5*multiply + x, y: 3*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)
            
            let strokePath7 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: 0.5*multiply + x, y: 3*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: 0.875*multiply + x, y: 1.75*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)
            
            let strokePath8 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: 0.875*multiply + x, y: 1.75*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: x, y: 1*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)
            
            let strokePath9 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: x, y: 1*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: 1*multiply + x, y: 1*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)
            
            let strokePath10 = PKStrokePath(controlPoints: [
                PKStrokePoint(location: CGPoint(x: 1*multiply + x, y: 1*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: 1.5*multiply + x, y: 0*multiply + y), timeOffset: 0, size: size, opacity: opacity, force: 0, azimuth: 0, altitude: 0)
            ], creationDate: creationDate)

            self = PKDrawing(strokes: [
                PKStroke(ink: ink, path: strokePath1),
                PKStroke(ink: ink, path: strokePath2),
                PKStroke(ink: ink, path: strokePath3),
                PKStroke(ink: ink, path: strokePath4),
                PKStroke(ink: ink, path: strokePath5),
                PKStroke(ink: ink, path: strokePath6),
                PKStroke(ink: ink, path: strokePath7),
                PKStroke(ink: ink, path: strokePath8),
                PKStroke(ink: ink, path: strokePath9),
                PKStroke(ink: ink, path: strokePath10),
            ])
            break
        }
    }
}

