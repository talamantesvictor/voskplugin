import { registerPlugin } from '@capacitor/core';
import type { VoskCapPlugin } from './definitions';

const VoskCap = registerPlugin<VoskCapPlugin>('VoskCap', {
  android: () => import('./android').then(m => new m.VoskCapAndroid()),
  ios: () => import('./ios').then(m => new m.VoskCapIOS()),
  web: () => import('./web').then(m => new m.VoskCapWeb()),
});

export * from './definitions';
export { VoskCap };
