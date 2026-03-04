<div align="center">

  <h1>openclaw-stimm-voice</h1>

  <p><b>Real-time voice conversations for OpenClaw — one agent talks fast, one agent thinks deep.</b></p>

  <a href="https://www.npmjs.com/package/openclaw-stimm-voice">
    <img src="https://img.shields.io/npm/v/openclaw-stimm-voice?label=npm" alt="npm">
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/node-%3E%3D22-green" alt="Node.js">
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/python-3.10%2B-blue" alt="Python">
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/livekit-compatible-purple" alt="LiveKit">
  </a>

</div>

<br>

> **Early days.** The voice assistant still stutters a bit — latency and fluency will improve as the project evolves. Feedback and contributions are very welcome.

Stimm Voice is a third-party OpenClaw plugin that adds real-time voice conversations to OpenClaw. A fast Python voice agent (LiveKit + STT/TTS/LLM) handles low-latency speech while OpenClaw acts as the reasoning supervisor.

## Provider support

| Role | Tested ✅ | May work, untested |
|---|---|---|
| **LLM** | Groq | OpenAI, Azure OpenAI, … |
| **TTS** | Deepgram | OpenAI, Cartesia, … |
| **STT** | Hume, ElevenLabs | … |

Contributions and test reports for other providers are very welcome.

## Install

**Prerequisites:** Node.js 22+, Python 3.10+, OpenClaw gateway ≥ 2026.2.0, a LiveKit deployment (local or cloud).

```bash
openclaw plugins install openclaw-stimm-voice
```

Restart the gateway, then run the setup wizard — it handles LiveKit credentials, provider selection, and Python extras:

```bash
openclaw voice:setup
```

## Usage

Start a voice session from CLI:

```bash
openclaw voice:start
```

Or just ask the OpenClaw agent in any conversation (WhatsApp, etc.):

> "Send me a Stimm Voice link"

The agent starts a session and replies with a one-time link to open on your phone.

---

## Reference

<details>
<summary>Config (manual / advanced)</summary>

Set config under `plugins.entries.stimm-voice.config`:

```json5
{
  enabled: true,
  livekit: {
    url: "wss://your-project.livekit.cloud",
    apiKey: "APIxxxxx",
    apiSecret: "your-secret",
  },
  web: {
    enabled: true,
    path: "/voice",
  },
  access: {
    mode: "quick-tunnel", // "none" | "quick-tunnel"
    claimTtlSeconds: 120,
    livekitTokenTtlSeconds: 300,
    supervisorSecret: "change-me",
    allowDirectWebSessionCreate: false,
    claimRateLimitPerMinute: 20,
  },
  voiceAgent: {
    spawn: { autoSpawn: true },
    stt: { provider: "deepgram", model: "nova-3" },
    tts: { provider: "openai", model: "gpt-4o-mini-tts", voice: "ash" },
    llm: { provider: "openai", model: "gpt-4o-mini" },
    bufferingLevel: "MEDIUM",
    mode: "hybrid",
  },
}
```

Notes:
- The extension is disabled by default (`enabled: false`).
- `access.mode="quick-tunnel"` requires `cloudflared` on PATH.
- `voiceAgent.tts.voice` is provider-specific: OpenAI uses voice names (`ash`, `alloy`), ElevenLabs uses `voice_id`, Cartesia uses voice UUIDs.
- API keys can be set directly in config or via env fallbacks (`STIMM_STT_API_KEY`, `STIMM_TTS_API_KEY`, `STIMM_LLM_API_KEY`).
- `access.supervisorSecret` supports env fallback (`STIMM_SUPERVISOR_SECRET`, then `OPENCLAW_SUPERVISOR_SECRET`).

</details>

<details>
<summary>OpenClaw tools profile</summary>

The voice supervisor calls the OpenClaw agent for reasoning and long-context decisions. For full capability (persistent memory, workspace files, tools), configure the `coding` profile:

```bash
openclaw config set tools.profile coding
```

The default `messaging` profile (since 2026-03-02) blocks filesystem tools — the agent can still respond but cannot write `IDENTITY.md`, `USER.md`, or workspace files.

</details>

<details>
<summary>Supervisor logs</summary>

```bash
openclaw voice:logs --limit 40
openclaw voice:logs --watch --interval 2
```

Options: `--raw`, `--limit <n>`, `--watch`, `--interval <s>`, `--all-events`.

Prints Stimm supervisor `OBS_JSON` events (`inference_started`, `inference_completed`, `trigger_sent`, `no_action`) and gateway-side `[stimm-voice:supervisor]` lines.

</details>

<details>
<summary>HTTP endpoints</summary>

- `GET <web.path>`: serves the web voice UI.
- `POST <web.path>/claim`: claim exchange endpoint.
- `POST <web.path>`: disabled by default (`403`) unless `access.allowDirectWebSessionCreate=true`.
- `POST /stimm/supervisor`: internal supervisor callback (protected by `access.supervisorSecret`).

Browser flow: open `shareUrl` → page calls `POST /voice/claim` with claim token → gateway returns a short-lived LiveKit token → browser joins LiveKit.

</details>

<details>
<summary>Gateway methods & tool API</summary>

Gateway methods: `stimm.start`, `stimm.end`, `stimm.status`, `stimm.instruct`, `stimm.mode`

Tool name `stimm_voice`, actions: `start_session`, `end_session`, `status`, `instruct`, `add_context`, `set_mode`

`stimm.start` / `start_session` returns room metadata, `shareUrl` (if quick tunnel enabled), and a one-time `claimToken`.

</details>

## Development

This section covers the local dev setup to iterate on the plugin without waiting
for npm publish cycles.

### Repos involved

| Repo | Role |
|---|---|
| `~/repos/openclaw` | OpenClaw core — gateway binary (`dist/index.js`) |
| `~/repos/openclaw-stimm-voice` | This plugin |
| `~/repos/stimm/packages/protocol-ts` | `@stimm/protocol` TypeScript package |

In **production**, a systemd user service runs the gateway automatically.
In **dev mode**, `dev-link.sh` stops that service so you can run the gateway
manually with `pnpm`, which also auto-rebuilds core if stale.

The gateway loads plugins at runtime using **jiti** (TypeScript interpreted
directly — no plugin build step needed).

### Setup dev mode

```bash
cd ~/repos/openclaw-stimm-voice
./scripts/dev-link.sh
```

This script:
1. Builds `@stimm/protocol` from source (required — jiti loads its `dist/`)
2. Symlinks `node_modules/@stimm/protocol` → `~/repos/stimm/packages/protocol-ts`
3. Symlinks `~/.openclaw/extensions/stimm-voice` → this repo
4. Stops the systemd service to free port 18789

Then start the gateway in the foreground (auto-rebuilds openclaw core if stale):

```bash
cd ~/repos/openclaw
pnpm openclaw gateway run --port 18789
```

### Workflow per change type

| What you modified | What to do |
|---|---|
| **Plugin** — `index.ts`, `voice.html`, `src/config.ts`… | `Ctrl+C` → `pnpm openclaw gateway run --port 18789` |
| **Protocol** — `~/repos/stimm/packages/protocol-ts/src/` | `npm run build` inside `protocol-ts/` → `Ctrl+C` → relancer le gateway |
| **OpenClaw core** — `~/repos/openclaw/src/` | `Ctrl+C` → `pnpm openclaw gateway run --port 18789` (rebuild auto) |

For continuous rebuild of `@stimm/protocol` during a session:

```bash
# Terminal dédié
./scripts/dev-watch-stimm.sh
```

### Restore production mode

```bash
./scripts/dev-unlink.sh
```

This removes all symlinks, restores the npm backup (or reinstalls from npm if no
backup), and restarts the systemd service.

### Architecture notes

- Plugin `.ts` files are loaded by jiti — **no compilation needed** after plugin
  changes, just restart the gateway.
- `@stimm/protocol` points its `main` to `dist/index.js`, so it **must be built**
  before any protocol change is visible to jiti.
- The systemd service is **production mode**. In dev mode, `dev-link.sh` stops it
  and you run `pnpm openclaw gateway run` instead, which rebuilds core automatically
  when `src/` is newer than `dist/`.
