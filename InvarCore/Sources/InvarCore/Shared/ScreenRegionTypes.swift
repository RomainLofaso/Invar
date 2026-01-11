import Foundation

public struct CaptureRegion: Equatable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct ScreenDescriptor: Equatable {
    public var displayID: Int

    public init(displayID: Int) {
        self.displayID = displayID
    }
}
