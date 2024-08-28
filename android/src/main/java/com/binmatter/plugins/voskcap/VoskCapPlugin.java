package com.binmatter.plugins.voskcap;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import android.content.Context;

@CapacitorPlugin(name = "VoskCap")
public class VoskCapPlugin extends Plugin {

    private VoskCap voskCap;

    @Override
    public void load() {
        Context context = getContext();
        voskCap = new VoskCap();
        voskCap.initModel(context);
    }

    @PluginMethod
    public void startRecognition(PluginCall call) {
        call.setKeepAlive(true);

        voskCap.startListening(new VoskCap.RecognizedTextListener() {
            @Override
            public void onTextRecognized(String text) {
                JSObject ret = new JSObject();
                ret.put("text", text);
                // call.resolve(ret);
                notifyListeners("onTextRecognized", ret);
            }
        });
    }

    @PluginMethod
    public void stopRecognition(PluginCall call) {
        voskCap.stopListening();
        call.resolve();
    }
}
