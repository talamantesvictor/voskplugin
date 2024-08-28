export interface VoskCapPlugin {
  startRecognition(): Promise<{ text: string }>;
  stopRecognition(): Promise<void>;
}
