import { WebPlugin } from '@capacitor/core';

import type { VoskCapPlugin } from './definitions';

export class VoskCapWeb extends WebPlugin implements VoskCapPlugin {
  async startRecognition(): Promise<{ text: string }> {
    console.warn('VoskCap: startRecognition is not implemented on web');
    return { text: '' };
  }

  async stopRecognition(): Promise<void> {
    console.warn('VoskCap: stopRecognition is not implemented on web');
    return;
  }
}
