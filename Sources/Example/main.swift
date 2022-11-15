import Foundation
import AVFoundation
import AudioProcessor

let deepness: Float = 0.1
let volume: Float = 1.0

let outputURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())output.wav")
let voiceURL = URL(fileURLWithPath: "/Users/vzhavoronkov/fun/AudioProcessor/Sources/Example/Resources/second.wav")
let asset = AVAsset(url: voiceURL)
let composition: AVComposition = {
    let composition = AVMutableComposition()
    guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0),
          let sourceAudioTrack = asset.tracks(withMediaType: .audio).first else  {
        fatalError("no audio tracks")
    }
    for _ in 0..<10 {
        try! audioTrack.insertTimeRange(sourceAudioTrack.timeRange, of: sourceAudioTrack, at: .invalid)
    }
    return composition
}()

let parameters = AudioFilterParameters(intensity: deepness, volume: volume)
let filter = CompositeFilter(filters: [BrownNoiseFilter(), LowPassAudioFilter()])
let processor: AudioProcessor = { floats, floatsCount in
    filter(floats: floats, floatsCount: floatsCount, params: parameters)
}
let player = try! Player(asset: composition, processor: processor)
let exporter = try! Exporter(asset: composition, processor: processor)

//player.play()

try? FileManager.default.removeItem(at: outputURL)
exporter.export(outputURL: outputURL) { result in
    switch result {
    case let .success(url):
        print("Exported file at \(url.path)")
    case let .failure(error):
        print("Got error during export: \(error)")
    }
}
RunLoop.main.run()
