import { WebPlugin } from '@capacitor/core';
import type { VoskCapPlugin } from './definitions';

export class VoskCapAndroid extends WebPlugin implements VoskCapPlugin {
  
  async startRecognition(): Promise<{ text: string }> {
    return new Promise((resolve, reject) => {
      (window as any).VoskCapPlugin.startRecognition((result: any) => {
        if (result.text) {
          resolve({ text: result.text });
        } else {
          reject('Recognition failed');
        }
      });
    });
  }

  async stopRecognition(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        (window as any).VoskCapPlugin.stopRecognition();
        resolve();
      } catch (error) {
        reject(error);
      }
    });
  }
}
