import Foundation
import AVFoundation

@objc public class VoskCap: NSObject {
    
    private var recognizer: OpaquePointer?
    private var model: OpaquePointer?
    private var audioEngine: AVAudioEngine!
    private var processingQueue: DispatchQueue!
    private var audioSession: AVAudioSession!

    @objc public var onResult: ((String) -> Void)?

    @objc public override init() {
        super.init()
        processingQueue = DispatchQueue(label: "recognizerQueue")
        audioSession = AVAudioSession.sharedInstance()
    }

    @objc public func initModel() {
        print("initModel")

        if let modelPath = Bundle.main.path(forResource: "vosk-model-small-es-0.42", ofType: nil) {
            self.model = vosk_model_new(modelPath.cString(using: .utf8))
            self.recognizer = vosk_recognizer_new(self.model, 16000.0)
            print("Model loaded from app bundle")
        } else {
            print("Error: Model path not found in app bundle, trying in POD")

            if let frameworkBundle = Bundle(for: VoskCap.self).resourcePath {
                let modelPath = frameworkBundle + "/vosk-model-small-es-0.42"
                self.model = vosk_model_new(modelPath.cString(using: .utf8))
                self.recognizer = vosk_recognizer_new(self.model, 16000.0)
                print("Model loaded from POD bundle")
            } else {
                print("Error: Model path not found in Pod bundle")
            }
        }

        // Move audio session setup to initModel for early initialization
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setPreferredSampleRate(16000)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session initialized and activated")
        } catch {
            print("Failed to initialize and activate AVAudioSession: \(error.localizedDescription)")
        }
    }

    @objc public func startListening() {
        guard audioEngine == nil else { return }

        do {
            let hwSampleRate = audioSession.sampleRate

            audioEngine = AVAudioEngine()
            let inputNode = audioEngine.inputNode

            let formatPcm = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: hwSampleRate, channels: 1, interleaved: true)!
            inputNode.installTap(onBus: 0, bufferSize: 2048, format: formatPcm) { buffer, time in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                    print("Error: Received non-PCM buffer")
                    return
                }

                self.processingQueue.async {
                    if let convertedBuffer = self.convertTo16000Hz(buffer: pcmBuffer, fromSampleRate: hwSampleRate) {
                        let recognizedText = self.recognizeData(buffer: convertedBuffer)

                        self.processingQueue.async {
                            if let data = recognizedText.data(using: .utf8) {
                                do {
                                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                        var result = ""

                                        if let partialText = json["partial"] as? String {
                                            result = """
                                            {
                                                "final": false,
                                                "text": "\(partialText)"
                                            }
                                            """
                                        } else if let finalText = json["text"] as? String {
                                            result = """
                                            {
                                                "final": true,
                                                "text": "\(finalText)"
                                            }
                                            """
                                        }

                                        DispatchQueue.main.async {
                                            self.onResult?(result)
                                        }
                                    }
                                } catch {
                                    print("Error parsing recognizedText as JSON: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            }

            audioEngine.prepare()
            try audioEngine.start()
            print("Audio engine started")

        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
    }

    @objc public func stopListening() {
        guard audioEngine != nil else { return }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }

        print("Audio engine stopped and session deactivated")
    }

    private func convertTo16000Hz(buffer: AVAudioPCMBuffer, fromSampleRate: Double) -> AVAudioPCMBuffer? {
        guard fromSampleRate != 16000 else { return buffer }

        let inputFormat = buffer.format
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)!

        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            print("Error: Unable to create converter")
            return nil
        }

        let frameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * 16000.0 / fromSampleRate)
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCapacity) else {
            print("Error: Unable to create converted buffer")
            return nil
        }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
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
