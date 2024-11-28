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
        loadModel()
        setupAudioSession()
    }

    private func loadModel() {
        if let modelPath = Bundle.main.path(forResource: "vosk-model-small-es-0.42", ofType: nil) {
            self.model = vosk_model_new(modelPath.cString(using: .utf8))
            self.recognizer = vosk_recognizer_new(self.model, 16000.0)
            print("Model loaded from app bundle")
        } else if let frameworkBundle = Bundle(for: VoskCap.self).resourcePath {
            let modelPath = frameworkBundle + "/vosk-model-small-es-0.42"
            self.model = vosk_model_new(modelPath.cString(using: .utf8))
            self.recognizer = vosk_recognizer_new(self.model, 16000.0)
            print("Model loaded from POD bundle")
        } else {
            print("Error: Model path not found in any bundle")
        }
    }

    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session initialized and activated")
            print("Actual Input Channels: \(audioSession.inputNumberOfChannels)")
        } catch {
            print("Failed to initialize and activate AVAudioSession: \(error.localizedDescription)")
        }
    }

    @objc public func startListening() {
        guard audioEngine == nil else { return }

        audioSession.requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                print("Permiso de micrófono autorizado")
                DispatchQueue.main.async {
                    self.startAudioEngine()
                }
            } else {
                print("Permiso de micrófono denegado")
                // Manejar la denegación de permisos según tus necesidades
            }
        }
    }

    private func startAudioEngine() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session reconfigured for recognition")

            audioEngine = AVAudioEngine()
            let inputNode = audioEngine.inputNode

            let inputFormat = inputNode.inputFormat(forBus: 0)
            print("Input Format Sample Rate: \(inputFormat.sampleRate)")
            print("Input Format Channels: \(inputFormat.channelCount)")

            guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
                print("Invalid input format")
                return
            }

            inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, time in
                guard let self = self else { return }

                self.processingQueue.async {
                    if let convertedBuffer = self.convertTo16000HzMono(buffer: buffer) {
                        let recognizedText = self.recognizeData(buffer: convertedBuffer)
                        if let data = recognizedText.data(using: .utf8) {
                            do {
                                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                    var resultDict: [String: Any] = [:]
                                    if let partialText = json["partial"] as? String {
                                        resultDict["final"] = false
                                        resultDict["text"] = partialText
                                    } else if let finalText = json["text"] as? String {
                                        resultDict["final"] = true
                                        resultDict["text"] = finalText
                                    }

                                    if let resultData = try? JSONSerialization.data(withJSONObject: resultDict, options: []),
                                       let resultString = String(data: resultData, encoding: .utf8) {
                                        DispatchQueue.main.async {
                                            self.onResult?(resultString)
                                        }
                                    }
                                }
                            } catch {
                                print("Error parsing recognizedText as JSON: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        print("Failed to convert buffer")
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

        print("Audio engine stopped")
    }

    private func convertTo16000HzMono(buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true) else {
            print("Failed to create output format")
            return nil
        }

        guard let converter = AVAudioConverter(from: buffer.format, to: outputFormat) else {
            print("Failed to create AVAudioConverter")
            return nil
        }

        let inputChannelCount = Int(buffer.format.channelCount)
        converter.channelMap = Array(repeating: 0, count: inputChannelCount)

        let ratio = outputFormat.sampleRate / buffer.format.sampleRate
        let frameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCapacity) else {
            print("Failed to create converted buffer")
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
        let dataLen = Int(buffer.frameLength * 2) // 2 bytes por muestra para pcmFormatInt16
        let channels = UnsafeBufferPointer(start: buffer.int16ChannelData, count: Int(buffer.format.channelCount))
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
