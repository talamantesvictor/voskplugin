import { WebPlugin } from '@capacitor/core';

import type { VoskCapPlugin } from './definitions';

export class VoskCapWeb extends WebPlugin implements VoskCapPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
