import { registerPlugin } from '@capacitor/core';

import type { VoskCapPlugin } from './definitions';

const VoskCap = registerPlugin<VoskCapPlugin>('VoskCap', {
  web: () => import('./web').then(m => new m.VoskCapWeb()),
});

export * from './definitions';
export { VoskCap };
