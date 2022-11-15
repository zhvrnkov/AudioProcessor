import Foundation
import AVFoundation

public class AudioProcessingTap {
    
    public enum Error: Swift.Error {
        case status(OSStatus)
        case noTap
    }
    
    public let processor: AudioProcessor

    private let tapInit: MTAudioProcessingTapInitCallback = {
        (tap, clientInfo, tapStorageOut) in
        tapStorageOut.pointee = clientInfo
    }

    private let process: MTAudioProcessingTapProcessCallback = {
        (tap: MTAudioProcessingTap, itemCount: CMItemCount, tapFlags: MTAudioProcessingTapFlags, bufferList: UnsafeMutablePointer<AudioBufferList>, itemCountP: UnsafeMutablePointer<CMItemCount>, tapFlagsP: UnsafeMutablePointer<MTAudioProcessingTapFlags>) -> Void in
        guard MTAudioProcessingTapGetSourceAudio(tap, itemCount, bufferList, tapFlagsP, nil, itemCountP) == noErr else {
            fatalError()
        }
        let this = Unmanaged<AudioProcessingTap>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
        let list = UnsafeMutableAudioBufferListPointer(bufferList)
        
        typealias T = Float
        let byteSize = list.unsafeMutablePointer.pointee.mBuffers.mDataByteSize
        let numberOfFrames = Int(byteSize / UInt32(MemoryLayout<T>.size))
        let datas = list.map { $0.mData!.assumingMemoryBound(to: T.self) }
        
        let channel = datas[0]
        this.processor(channel, numberOfFrames)
        for otherChannel in list.dropFirst() {
            otherChannel.mData?.copyMemory(from: .init(channel), byteCount: .init(otherChannel.mDataByteSize))
        }
    }

    public private(set) var tap: Unmanaged<MTAudioProcessingTap>!
    init(processor: @escaping AudioProcessor) throws {
        self.processor = processor
        var tap: Unmanaged<MTAudioProcessingTap>?
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            init: tapInit,
            finalize: nil,
            prepare: nil,
            unprepare: nil,
            process: process
        )
        let err = MTAudioProcessingTapCreate(nil, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        guard let tap,
              err == noErr else {
            throw Error.status(err)
        }
        #warning("probably we should memory manage this tap but I don't care now")
        self.tap = tap
    }
}
