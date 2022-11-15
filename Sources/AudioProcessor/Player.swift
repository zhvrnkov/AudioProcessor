import Foundation
import AVFoundation

public class Player {
    
    public let processor: AudioProcessor
    public let tap: AudioProcessingTap
    public let asset: AVAsset
    
    public init(
        asset: AVAsset,
        processor: @escaping AudioProcessor
    ) throws {
        self.asset = asset
        self.processor = processor
        self.tap = try AudioProcessingTap(processor: processor)
    }
    
    private lazy var audioMix: AVAudioMix = {
        let audioTrack = asset.tracks(withMediaType: .audio)[0]
        let audioMix = AVMutableAudioMix()
        let params = AVMutableAudioMixInputParameters(track: audioTrack)
        
        params.audioTapProcessor = tap.tap.takeRetainedValue()
        audioMix.inputParameters.append(params)
        
        return audioMix
    }()
    
    private lazy var playerItem: AVPlayerItem = {
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.audioMix = audioMix
        return playerItem
    }()
    private lazy var looper: AVPlayerLooper = {
        return .init(player: player, templateItem: playerItem)
    }()
    private lazy var player: AVQueuePlayer = {
        return .init(items: [playerItem])
    }()
    
    public func play() {
        _ = looper
        player.play()
    }
}
