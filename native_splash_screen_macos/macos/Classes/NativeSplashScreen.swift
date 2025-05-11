import AppKit
import Cocoa

public class NativeSplashScreen {
    // MARK: - Public Configuration

    public static var configurationProvider: NativeSplashScreenConfigurationProvider?
    
    // MARK: - Private State

    private static var splashWindow: NSWindow?
    private static var isSplashShown: Bool = false
    
    // MARK: - Public Methods
    
    public static func show() {
        guard Thread.isMainThread else {
            DispatchQueue.main.sync { show() }
            return
        }
        
        guard !isSplashShown else { return }
        
        guard let config = configurationProvider else {
            print("NativeSplashScreen: ERROR - ConfigurationProvider not set. Splash screen cannot be shown.")
            return
        }
        
        guard config.windowWidth > 0, config.windowHeight > 0 else {
            print("NativeSplashScreen: WARNING - Invalid window dimensions provided (<=0). Splash not shown.")
            return
        }
        
        let window = createSplashWindow(config: config)
        
        if let image = createImageFromPixelBytes(bytes: config.imagePixels,
                                                 width: config.imageWidth,
                                                 height: config.imageHeight)
        {
            let imageView = createImageView(with: image, windowSize: window.frame.size)
            window.contentView?.addSubview(imageView)
        } else {
            print("NativeSplashScreen: WARNING - Failed to create image from provided pixel data. Window will be blank.")
        }
        
        Self.splashWindow = window
        displaySplashWindow(window, animated: config.withAnimation)
        isSplashShown = true
    }
    
    public static func close(effect: String = "") {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { close(effect: effect) }
            return
        }
        
        guard isSplashShown, let window = splashWindow else { return }

        let fadeDuration = 0.3
        let slideDistance: CGFloat = 50.0
        
        let completionHandler = {
            window.orderOut(nil)
            Self.splashWindow = nil // Allow ARC to deallocate
            Self.isSplashShown = false
        }
        
        if effect.isEmpty {
            completionHandler()
            return
        }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = fadeDuration
            switch effect.lowercased() {
            case "fade":
                window.animator().alphaValue = 0.0
            case "slide_up_fade":
                window.animator().alphaValue = 0.0
                var newFrame = window.frame
                newFrame.origin.y += slideDistance
                window.animator().setFrame(newFrame, display: true, animate: true)
            case "slide_down_fade":
                window.animator().alphaValue = 0.0
                var newFrame = window.frame
                newFrame.origin.y -= slideDistance
                window.animator().setFrame(newFrame, display: true, animate: true)
            default:
                window.animator().alphaValue = 0.0
            }
        }, completionHandler: completionHandler)
    }
    
    // MARK: - Private Helper Methods

    private static func createSplashWindow(config: NativeSplashScreenConfigurationProvider) -> NSWindow {
        let contentRect = NSRect(x: 0, y: 0, width: CGFloat(config.windowWidth), height: CGFloat(config.windowHeight))
        
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = NSWindow.Level.floating
        window.hasShadow = false
        window.title = config.windowTitle // Important for accessibility

        if let mainScreen = NSScreen.main {
            let screenRect = mainScreen.visibleFrame
            let xPos = (screenRect.width - contentRect.width) / 2.0 + screenRect.origin.x
            let yPos = (screenRect.height - contentRect.height) / 2.0 + screenRect.origin.y
            window.setFrameOrigin(NSPoint(x: xPos, y: yPos))
        }
        
        // Always assign a new content view for custom drawing or subviews.
        window.contentView = NSView(frame: contentRect)
        return window
    }

    private static func createImageFromPixelBytes(bytes: [UInt8], width: Int, height: Int) -> NSImage? {
        // Assume width and height from config are valid if imageBytes is not empty,
        // as the protocol makes imageBytes non-optional, implying an image is always expected.
        // The CLI should ensure width*height*4 == bytes.count.
        guard width > 0, height > 0, !bytes.isEmpty else { return nil }
        
        let bitsPerComponent = 8
        let bitsPerPixel = 32 // ARGB = 4 bytes
        let bytesPerRow = width * 4
        let expectedTotalBytes = bytesPerRow * height

        guard bytes.count == expectedTotalBytes else {
            // This is a significant error if CLI guarantees data integrity.
            // A print statement here is justified for debugging bad generated data.
            print("NativeSplashScreen: ERROR - Pixel data size (\(bytes.count)) does not match expected size (\(expectedTotalBytes)) for \(width)x\(height) image.")
            return nil
        }

        // Convert [UInt8] to Data for CGDataProvider
        let data = Data(bytes)

        let cgImage = data.withUnsafeBytes { (unsafeRawBufferPointer: UnsafeRawBufferPointer) -> CGImage? in
            guard let baseAddress = unsafeRawBufferPointer.baseAddress else { return nil }
            
            guard let providerRef = CGDataProvider(dataInfo: nil, data: baseAddress, size: data.count, releaseData: { _, _, _ in
                // Data is owned by the `data` local var, which will go out of scope.
                // CGDataProvider will retain the data pointer. This is generally okay
                // as `Data` copies the bytes, so the buffer from `bytes` is safe here.
            }) else { return nil }
            
            // Assuming ARGB byte order: A, R, G, B sequentially for each pixel.
            // When interpreted as a UInt32, if A is most significant, it's Big Endian.
            // Common pixel formats might store as BGRA on little-endian systems when mapped to UInt32,
            // but if your byte array is literally A then R then G then B, then using
            // kCGImageAlphaPremultipliedFirst with CGBitmapInfo.byteOrder32Big is typical for ARGB.
            // If your data is truly BGRA bytes, then use CGBitmapInfo.byteOrder32Little
            // and perhaps kCGImageAlphaPremultipliedLast or kCGImageAlphaLast.
            // Sticking to ARGB (Alpha First, components in R,G,B order) for byte array:
            let bitmapInfo: CGBitmapInfo = [
                CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                CGBitmapInfo.byteOrder32Little // Pixel data is treated as little-endian 32-bit (e.g. 0xAARRGGBB)
            ]
            return CGImage(
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bitsPerPixel: bitsPerPixel,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo,
                provider: providerRef,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
            )
        }
        
        if let validCGImage = cgImage {
            return NSImage(cgImage: validCGImage, size: NSSize(width: width, height: height))
        }
        return nil
    }

    private static func createImageView(with image: NSImage, windowSize: NSSize) -> NSImageView {
        let imageView = NSImageView(image: image)
        imageView.imageScaling = .scaleProportionallyUpOrDown // Sensible default

        let imageX = (windowSize.width - image.size.width) / 2.0
        let imageY = (windowSize.height - image.size.height) / 2.0
        
        imageView.frame = NSRect(x: imageX, y: imageY, width: image.size.width, height: image.size.height)
        return imageView
    }
    
    private static func displaySplashWindow(_ window: NSWindow, animated: Bool) {
        if animated {
            window.alphaValue = 0.0
            window.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3 // Standard fade duration
                window.animator().alphaValue = 1.0
            }, completionHandler: nil)
        } else {
            window.alphaValue = 1.0
            window.makeKeyAndOrderFront(nil)
        }
    }
}
