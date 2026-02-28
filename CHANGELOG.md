# Changelog

## [1.0.1](https://github.com/EtienneLescot/openclaw-stimm-voice/compare/v1.0.0...v1.0.1) (2026-02-28)


### Bug Fixes

* **stimm-voice:** align plugin and service id to npm package name (openclaw-stimm-voice) ([b641f8e](https://github.com/EtienneLescot/openclaw-stimm-voice/commit/b641f8e505a81a51378ad7c3daba57347861c674))
* **stimm-voice:** reduce scanner warnings — isolate child_process and process.env into dedicated helpers ([33ddd90](https://github.com/EtienneLescot/openclaw-stimm-voice/commit/33ddd9098c4ce5837be4fdef62601279bd75e7e9))

## 1.0.0 (2026-02-28)


### Features

* **stimm-voice:** dual-agent pipeline — OpenClaw supervisor bridge, room manager, response generator ([934afb0](https://github.com/EtienneLescot/openclaw-stimm-voice/commit/934afb0217f18b04e33e0c1fcbc94c9910041357))
* **stimm-voice:** extension scaffold — plugin manifest, entrypoint, core config types ([a981bf3](https://github.com/EtienneLescot/openclaw-stimm-voice/commit/a981bf392c953fe13532aefde3b4c364d27041b6))
* **stimm-voice:** interactive setup wizard — multi-provider catalog (Deepgram, ElevenLabs, Hume, Groq, OpenAI) ([6d7c0ca](https://github.com/EtienneLescot/openclaw-stimm-voice/commit/6d7c0caabadb4a89d3ecb555a20159f056cba0c8))
* **stimm-voice:** Python voice agent — LiveKit Agents v1 entrypoint, STT/TTS/LLM plugin support ([2965ebf](https://github.com/EtienneLescot/openclaw-stimm-voice/commit/2965ebf2eec995473e1f95ee596ce8e21fd0de95))
* **stimm-voice:** web voice UI, claim-token flow, and CLI commands (voice:start, voice:logs, voice:setup) ([92f611f](https://github.com/EtienneLescot/openclaw-stimm-voice/commit/92f611fd16f4011ef4e415a47928f0188c5394d9))


### Bug Fixes

* **stimm-voice:** WSL2/Docker WebRTC — LD_PRELOAD shim for Nvidia crashes, TCP+UDP port mapping, TURN credentials ([e769b65](https://github.com/EtienneLescot/openclaw-stimm-voice/commit/e769b65d197b8c7df1f69035a009121a82d9e5cc))
