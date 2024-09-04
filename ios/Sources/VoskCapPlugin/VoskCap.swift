import Foundation
import AVFoundation

@objc public class VoskCap: NSObject {
    
    private var recognizer: OpaquePointer?
    private var model: OpaquePointer?
    private var audioEngine: AVAudioEngine!
    private var processingQueue: DispatchQueue!
    
    @objc public var onResult: ((String) -> Void)?
    
    @objc public override init() {
        super.init()
        processingQueue = DispatchQueue(label: "recognizerQueue")
    }
    
    @objc public func initModel() {
        NSLog("initModel")


        if let modelPath = Bundle.main.path(forResource: "vosk-model-small-es-0.42", ofType: nil) {
            self.model = vosk_model_new(modelPath.cString(using: .utf8))
            self.recognizer = vosk_recognizer_new(self.model, 16000.0)
            NSLog("Model loaded from app bundle")
        } else {
            NSLog("Error: Model path not found in app bundle, trying in POD")

            if let frameworkBundle = Bundle(for: VoskCap.self).resourcePath {
                let modelPath = frameworkBundle + "/vosk-model-small-es-0.42"
                self.model = vosk_model_new(modelPath.cString(using: .utf8))
                self.recognizer = vosk_recognizer_new(self.model, 16000.0)
                NSLog("Model loaded from POD bundle")
            } else {
                NSLog("Error: Model path not found in Pod bundle")
            }
        }
    }
    
    @objc public func startListening() {
        guard audioEngine == nil else { return }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setPreferredSampleRate(16000)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let hwSampleRate = audioSession.sampleRate
            
            audioEngine = AVAudioEngine()
            let inputNode = audioEngine.inputNode
            
            let formatPcm = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: hwSampleRate, channels: 1, interleaved: true)!
            
            inputNode.installTap(onBus: 0, bufferSize: 8192, format: formatPcm) { buffer, time in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                    print("Error: Received non-PCM buffer")
                    return
                }
                
                self.processingQueue.async {
                    if let convertedBuffer = self.convertTo16000Hz(buffer: pcmBuffer, fromSampleRate: hwSampleRate) {
                        let recognizedText = self.recognizeData(buffer: convertedBuffer)
                        DispatchQueue.main.async {
                            self.onResult?(recognizedText)
                        }
                    }
                }
            }
            
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
    }
    
    @objc public func stopListening() {
        guard audioEngine != nil else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    private func convertTo16000Hz(buffer: AVAudioPCMBuffer, fromSampleRate: Double) -> AVAudioPCMBuffer? {
        guard fromSampleRate != 16000 else { return buffer }

        let inputFormat = buffer.format
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)!

        let converter = AVAudioConverter(from: inputFormat, to: outputFormat)
        
        let frameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * 16000.0 / fromSampleRate)
        let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCapacity)!

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        let status = converter?.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
        
        if status == .error || error != nil {
            print("Error during conversion: \(String(describing: error))")
            return nil
        }

        return convertedBuffer
    }
    
    private func recognizeData(buffer: AVAudioPCMBuffer) -> String {
        let dataLen = Int(buffer.frameLength * 2)
        let channels = UnsafeBufferPointer(start: buffer.int16ChannelData, count: 1)
        let endOfSpeech = channels[0].withMemoryRebound(to: Int8.self, capacity: dataLen) {
            vosk_recognizer_accept_waveform(recognizer, $0, Int32(dataLen))
        }
        let res = endOfSpeech == 1 ? vosk_recognizer_final_result(recognizer) : vosk_recognizer_partial_result(recognizer)
        return String(validatingUTF8: res!) ?? ""
    }
    
    deinit {
        stopListening()
        vosk_recognizer_free(self.recognizer)
        vosk_model_free(self.model)
    }
}
