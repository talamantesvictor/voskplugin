import Foundation
import Capacitor

@objc(VoskCapPlugin)
public class VoskCapPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "VoskCapPlugin"
    public let jsName = "VoskCap"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "startRecognition", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopRecognition", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = VoskCap()

    override public func load() {
        super.load()
        implementation.initModel()

        // Configurar onResult para notificar a los listeners de JavaScript
        implementation.onResult = { [weak self] result in
            self?.notifyListeners("onTextRecognized", data: ["text": result])
        }
    }

    @objc func startRecognition(_ call: CAPPluginCall) {
        implementation.startListening()
        call.resolve()
    }

    @objc func stopRecognition(_ call: CAPPluginCall) {
        implementation.stopListening()
        call.resolve()
    }
}
