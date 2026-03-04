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

Stimm Voice is a third-party OpenClaw plugin for real-time voice conversations.

It uses a dual-agent architecture:

- A fast Python voice agent (LiveKit + STT/TTS/LLM) handles low-latency speech.
- OpenClaw acts as the supervisor for reasoning, tools, and long-context decisions.

## Provider support

The following providers have been tested end-to-end:

| Role | Tested providers |
|---|---|
| **LLM** | Groq ✅ |
| **TTS** | Deepgram ✅ |
| **STT** | Hume ✅, ElevenLabs ✅ |

Other providers supported by Stimm may work but haven't been validated yet. Contributions and test reports are very welcome.

## Presentation

What this plugin provides:

- Real-time voice sessions backed by LiveKit rooms.
- Browser entrypoint at `web.path` (default: `/voice`).
- Claim-token flow for web access (`/voice/claim`) with one-time, short-lived claims.
- Optional Cloudflare Quick Tunnel for temporary public access.
- Optional supervisor shared secret for `POST /stimm/supervisor`.

## Install

### Prerequisites

- Node.js 22+
- Python 3.10+
- OpenClaw gateway ≥ 2026.2.0 installed and running
- LiveKit deployment:
  - local (`ws://localhost:7880`) or
  - cloud (`wss://<your-project>.livekit.cloud`)

### Install from npm

```bash
openclaw plugins install openclaw-stimm-voice
```

### Install from GitHub (latest)

```bash
openclaw plugins install https://github.com/EtienneLescot/openclaw-stimm-voice
```

Then restart the OpenClaw gateway.

Python dependencies use Stimm extras as the single installation contract:

- Base/default profile from [python/requirements.txt](python/requirements.txt): `stimm[deepgram,openai]`
- Additional provider plugins are installed by the setup wizard based on selected STT/TTS/LLM providers (`stimm[...]`).

## Config

Set config under `plugins.entries.stimm-voice.config`.

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
- `voiceAgent.tts.voice` is provider-specific: OpenAI uses voice names (`ash`, `alloy`), ElevenLabs uses `voice_id`, and Cartesia uses voice UUIDs.
- API keys can be set directly in plugin config, or via env fallbacks (`STIMM_STT_API_KEY`, `STIMM_TTS_API_KEY`, `STIMM_LLM_API_KEY`, then provider-specific env vars).
- `access.supervisorSecret` also supports env fallback (`STIMM_SUPERVISOR_SECRET`, then `OPENCLAW_SUPERVISOR_SECRET`).

### OpenClaw tools profile

The voice supervisor calls the OpenClaw agent to handle reasoning and long-context
decisions. For the agent to be useful (persist identity, write workspace files,
use tools), OpenClaw must be configured with at least the `coding` tools profile.

The default profile set by the OpenClaw onboarding wizard is `messaging` (since
2026-03-02), which **blocks filesystem tools** — the agent can still respond but
cannot write `IDENTITY.md`, `USER.md`, or any workspace file.

To enable full agent capability:

```bash
openclaw config set tools.profile coding
```

Then restart the gateway. Without this, the supervisor agent will answer
conversationally but will have no persistent memory across voice sessions.

## Usage

### Start session from CLI/tool/gateway

```bash
openclaw voice:start --channel web
```

### Supervisor logs (high-level)

Use this command to inspect supervisor observability quickly without manual `grep`:

```bash
openclaw voice:logs --limit 40
```

Interactive follow mode:

```bash
openclaw voice:logs --watch --interval 2
```

Options:

- `--raw`: print raw `OBS_JSON` lines from `/tmp/stimm-agent.log`
- `--limit <n>`: number of entries to print (default: `40`)
- `--watch`: keep watching and print new entries continuously (Ctrl+C to stop)
- `--interval <s>`: refresh interval for watch mode in seconds (default: `2`)
- `--all-events`: include `inference_started` (hidden by default to reduce noise)

The command prints two sections:

- Stimm supervisor `OBS_JSON` events (`inference_started`, `inference_completed`, `trigger_sent`, `no_action`)
- Gateway-side synthesized lines (`[stimm-voice:supervisor]`) when available

`stimm.start` / `stimm_voice:start_session` returns:

- room metadata
- `shareUrl` (when quick tunnel is enabled)
- one-time `claimToken`

### Browser flow

1. Open the returned `shareUrl` on phone.
2. The page calls `POST /voice/claim` with the claim token.
3. Gateway validates claim and returns a short-lived LiveKit token.
4. Browser joins LiveKit.

### HTTP endpoints

- `GET <web.path>`: serves the web voice UI.
- `POST <web.path>/claim`: claim exchange endpoint.
- `POST <web.path>`: disabled by default (`403`) unless `access.allowDirectWebSessionCreate=true`.
- `POST /stimm/supervisor`: internal supervisor callback (protected if `access.supervisorSecret` is set).

### Gateway methods

- `stimm.start`
- `stimm.end`
- `stimm.status`
- `stimm.instruct`
- `stimm.mode`

### Tool

Tool name: `stimm_voice`

Actions:

- `start_session`
- `end_session`
- `status`
- `instruct`
- `add_context`
- `set_mode`

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
