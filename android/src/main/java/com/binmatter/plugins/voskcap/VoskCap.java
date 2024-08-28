package com.binmatter.plugins.voskcap;

import android.util.Log;
import android.content.Context;
import org.vosk.Model;
import org.vosk.Recognizer;
import org.vosk.android.SpeechService;
import org.vosk.android.RecognitionListener;
import java.io.IOException;
import org.json.JSONObject;
import org.json.JSONException;

public class VoskCap {

    private Recognizer recognizer;
    private SpeechService speechService;
    private Model model;

    public VoskCap() {
        Log.d("VoskCap", "VoskCap constructor call");
    }

    public void initModel(Context context) {
        try {
            Log.d("VoskCap", "Initialize Vosk model");

            String modelPath = context.getCacheDir().getAbsolutePath() + "/vosk-model-small-es-0.42";
            model = new Model(modelPath);

            Log.d("VoskCap", "Model successfully created");

            recognizer = new Recognizer(model, 16000.0f);
            speechService = new SpeechService(recognizer, 16000.0f);
        } catch (IOException e) {
            Log.e("VoskCap", "Error loading the model", e);
        } catch (Exception e) {
            Log.e("VoskCap", "Unexpected error", e);
        }
    }

    public void startListening(final RecognizedTextListener listener) {
        try {
            Log.d("VoskCap", "StartListening with SpeechService");
            speechService.startListening(new RecognitionListener() {
                @Override
               public void onPartialResult(String hypothesis) {
                  try {
                     JSONObject jsonObject = new JSONObject(hypothesis);
                     String recognizedText = "{\"final\": false, \"text\": \"" + jsonObject.getString("partial") + "\"}";
                     listener.onTextRecognized(recognizedText);
                     Log.d("VoskCap", recognizedText);
                  } catch (JSONException e) {
                     Log.e("VoskCap", "JSON parsing error", e);
                  }
               }

               @Override
               public void onResult(String hypothesis) {
                  try {
                     Log.d("VoskCap/Hypothesis", hypothesis);
                     JSONObject jsonObject = new JSONObject(hypothesis);
                     String recognizedText = "{\"final\": true, \"text\": \"" + jsonObject.getString("text") + "\"}";
                     listener.onTextRecognized(recognizedText);
                     Log.d("VoskCap", recognizedText);
                  } catch (JSONException e) {
                     Log.e("VoskCap", "JSON parsing error", e);
                  }
               }

               @Override
               public void onFinalResult(String hypothesis) {
                  try {
                     Log.d("VoskCap/Hypothesis", hypothesis);
                     JSONObject jsonObject = new JSONObject(hypothesis);
                     String recognizedText = "{\"final\": true, \"text\": \"" + jsonObject.getString("text") + "\"}";
                     listener.onTextRecognized(recognizedText);
                     Log.d("VoskCap", recognizedText);
                  } catch (JSONException e) {
                     Log.e("VoskCap", "JSON parsing error", e);
                  }
               }

                @Override
                public void onError(Exception e) {
                    Log.e("VoskCap", "Voice recognition error", e);
                }

                @Override
                public void onTimeout() {
                    Log.d("VoskCap", "Timeout during voice recognition");
                }
            });

        } catch (Exception e) {
            Log.e("VoskCap", "StartListening error", e);
        }
    }

    public void stopListening() {
        if (speechService != null) {
            speechService.stop();
            Log.d("VoskCap", "Stop listening");
        } else {
            Log.d("VoskCap", "speechService is null error");
        }
    }

    public interface RecognizedTextListener {
        void onTextRecognized(String text);
    }
}
