import type { VoskCapPlugin } from './definitions';

export class VoskCapIOS implements VoskCapPlugin {
  
   async startRecognition(): Promise<{ text: string }> {
      console.log('Attempting to start recognition');
      return new Promise((resolve, reject) => {
        try {
          console.log('Calling native method');
          (window as any).VoskCapPlugin.startRecognition((result: any) => {
            if (result.text) {
              console.log('Recognition successful', result.text);
              resolve({ text: result.text });
            } else {
              console.log('Recognition failed');
              reject('Recognition failed');
            }
          });
        } catch (error) {
          console.error('Error in startRecognition:', error);
          reject(error);
        }
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
