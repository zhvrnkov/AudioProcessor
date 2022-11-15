import Foundation
import AVFoundation

public class Exporter {
    public let processor: AudioProcessor
    public let tap: AudioProcessingTap
    public let asset: AVAsset
    
    public init(asset: AVAsset, processor: @escaping AudioProcessor) throws {
        self.asset = asset
        self.processor = processor
        self.tap = try AudioProcessingTap(processor: processor)
    }
    
    public func export(
        outputURL: URL,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let audioMix: AVAudioMix = {
            let audioTrack = asset.tracks(withMediaType: .audio)[0]
            let audioMix = AVMutableAudioMix()
            let params = AVMutableAudioMixInputParameters(track: audioTrack)
            
            params.audioTapProcessor = tap.tap.takeRetainedValue()
            audioMix.inputParameters.append(params)
            
            return audioMix
        }()
        let exportSession: AVAssetExportSession = {
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
            exportSession.outputFileType = .mov
            exportSession.outputURL = outputURL
            exportSession.metadata = asset.metadata
            exportSession.audioMix = audioMix
            return exportSession
        }()
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(.success(outputURL))
            default:
                completion(.failure(exportSession.error!))
            }
        }
    }
}
