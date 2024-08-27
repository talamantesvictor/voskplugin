export interface VoskCapPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
