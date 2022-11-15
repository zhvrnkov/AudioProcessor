import Foundation
import Accelerate

public typealias AudioProcessor = (UnsafeMutablePointer<Float>, Int) -> Void

public struct AudioFilterParameters {
    public var intensity: Float = 1.0
    public var volume: Float = 1.0
    
    public init(intensity: Float = 1.0, volume: Float = 1.0) {
        self.intensity = intensity
        self.volume = volume
    }
}

public protocol AudioFilter: AnyObject {
    var lastSample: Float? { get set }
    func callAsFunction(
        floats: UnsafeMutablePointer<Float>,
        floatsCount: Int,
        params: AudioFilterParameters
    )
}

public class LowPassAudioFilter: AudioFilter {
    public var lastSample: Float?
    
    public init() {}
    public func callAsFunction(
        floats: UnsafeMutablePointer<Float>,
        floatsCount: Int,
        params: AudioFilterParameters
    ) {
        let dt: Float = 0.01
        let RC: Float = 1
        let a = params.intensity // dt / (RC + dt)
        for i in 1..<floatsCount {
            floats[i] = a * floats[i] + (1 - a) * floats[i - 1]
        }
    }
}

public class WhiteNoiseFilter: AudioFilter {
    public var lastSample: Float?
    
    public init() {}
    public func callAsFunction(
        floats: UnsafeMutablePointer<Float>,
        floatsCount: Int,
        params: AudioFilterParameters
    ) {
        for i in 0..<floatsCount {
            floats[i] = Float.random(in: -1...1)
        }
    }
}

public class BrownNoiseFilter: AudioFilter {
    public var lastSample: Float?
    private let whiteNoise = WhiteNoiseFilter()
    
    public init() {}

    public func callAsFunction(
        floats: UnsafeMutablePointer<Float>,
        floatsCount: Int,
        params: AudioFilterParameters
    ) {
        func wn(_ floats: UnsafeMutablePointer<Float>, _ count: Int, A: Float) {
            whiteNoise(floats: floats, floatsCount: count, params: params)
            var A = A
            vDSP_vsmul(floats, 1, &A, floats, 1, .init(floatsCount))
        }
        let V = params.volume
        let A = 0.001 * V
        if let lastSample {
            floats[0] = lastSample
        }
        else {
            wn(floats, 1, A: 0.005 * V)
        }
        for i in 1..<floatsCount {
            var noise: Float = .random(in: -1...1) * A
            floats[i] = floats[i - 1] + noise
            if floats[i] > 1.0 || floats[i] < -1.0 {
                floats[i] -= 2 * noise
            }
        }
    }
}

public class CompositeFilter: AudioFilter {
    
    public var lastSample: Float? {
        didSet {
            for filter in filters {
                filter.lastSample = lastSample
            }
        }
    }
    public let filters: [AudioFilter]
    public init(filters: [AudioFilter]) {
        self.filters = filters
    }
    
    public func callAsFunction(floats: UnsafeMutablePointer<Float>, floatsCount: Int, params: AudioFilterParameters) {
        for filter in filters {
            filter(floats: floats, floatsCount: floatsCount, params: params)
        }
        lastSample = floats[floatsCount - 1]
    }
}
