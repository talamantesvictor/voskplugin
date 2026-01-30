# VoskPlugin
## Vosk Plugin for Ionic / Capacitor

A lightweight Capacitor plugin that enables **offline speech recognition** using the
[Vosk](https://alphacephei.com/vosk/) engine, designed to be used in **Ionic / Angular**
applications.

This plugin provides a simple bridge between Ionic apps and the native Vosk
speech-to-text capabilities, without relying on cloud services.

---

## Features

- 🎙️ Offline speech recognition (no internet required)
- 📱 Ionic / Capacitor compatible
- ⚡ Native performance via Vosk
- 🔌 Simple API surface
- 🧩 Designed to be extended or customized

---

## Supported Platforms

- ✅ Android  
- ✅ iOS

---

## Installation

```bash
npm install voskplugin
npx cap sync
```
---

## Models
A Vosk model may be present in this repository **for development and testing purposes only**.

The model is **not required** and **not intended for production use**.

For real applications, you must download a compatible model directly from the
official Vosk website:
👉 https://alphacephei.com/vosk/models

add it to the following paths:

Android
```android/src/main/assets/```
iOS
```ios/Sources/Resources/```

and update VoskCap.java & VoskCap.swift with the updated path.

---

## Basic Usage
```
import { VoskPlugin } from 'voskplugin';

await VoskPlugin.initialize({
  modelPath: 'vosk-model-small-en-us'
});

VoskPlugin.startListening();

VoskPlugin.addListener('onResult', (result) => {
  console.log('Recognized text:', result.text);
});
```

## Project Status

This plugin was originally created for **personal use** to solve a specific need.

It has been made public in case it helps others save time or serves as a reference
for similar integrations.

⚠️ **This project is not actively maintained.**
No ongoing development, roadmap, or guaranteed support should be expected.

That said, the code is functional, extensible, and free to use under the terms of
the Apache 2.0 license.


## LICENSE
Apache 2.0
