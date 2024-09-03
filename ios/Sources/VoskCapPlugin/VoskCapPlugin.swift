import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(VoskCapPlugin)
public class VoskCapPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "VoskCapPlugin"
    public let jsName = "VoskCap"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "startRecognition", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopRecognition", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = VoskCap()

    @objc func startRecognition(_ call: CAPPluginCall) {
        implementation.startRecognition { (text, error) in
            if let error = error {
                call.reject("Recognition failed", nil, error)
            } else if let text = text {
                call.resolve([
                    "text": text
                ])
            } else {
                call.reject("Recognition failed with no error or text")
            }
        }
    }

    @objc func stopRecognition(_ call: CAPPluginCall) {
        implementation.stopRecognition { error in
            if let error = error {
                call.reject("Failed to stop recognition", nil, error)
            } else {
                call.resolve()
            }
        }
    }
}
