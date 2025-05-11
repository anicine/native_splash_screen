public protocol NativeSplashScreenConfigurationProvider {
    // Window Properties
    var windowWidth: Int { get }
    var windowHeight: Int { get }
    var windowTitle: String { get }

    // Animation Properties
    var withAnimation: Bool { get }

    // Image Properties
    var imagePixels: [UInt8] { get } // ARGB Data (Little Endian)
    var imageWidth: Int { get } // Relevant only if imagePixelData is not nil
    var imageHeight: Int { get } // Relevant only if imagePixelData is not nil
}
