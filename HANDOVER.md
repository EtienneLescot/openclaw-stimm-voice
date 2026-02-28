# Handover — openclaw-stimm-voice standalone plugin

## Situation actuelle

Le code du plugin est dans `extensions/stimm-voice/` du monorepo
`EtienneLescot/openclaw` (branche `feat/livekit-stimm-voice`).

Le plugin a été **renommé** `openclaw-stimm-voice` (hors scope `@openclaw`) et les
fichiers de scaffolding standalone ont été ajoutés, mais le contenu n'a pas encore
été déplacé dans un repo dédié.

---

## Ce qu'il reste à faire

### 1. Créer le repo GitHub `EtienneLescot/openclaw-stimm-voice`

```bash
gh repo create EtienneLescot/openclaw-stimm-voice --public --description \
  "OpenClaw third-party plugin — Stimm dual-agent real-time voice"
```

---

### 2. Copier le contenu et recréer les commits

Copie le contenu de `extensions/stimm-voice/` à la racine du nouveau repo, sans
`node_modules/`.

Recréer les commits dans l'ordre ci-dessous. Les commits Codex review (nombreux
petits fix itératifs) sont **fusionnés en un seul** commit `fix` pour garder un
historique propre.

#### Commits à recréer (du plus ancien au plus récent)

---

**1. `feat(stimm-voice): extension scaffold — plugin manifest, entrypoint, core config types`**

Fichiers : `README.md`, `index.ts`, `openclaw.plugin.json`, `package.json`,
`src/config.ts`, `src/config.test.ts`

---

**2. `feat(stimm-voice): dual-agent pipeline — OpenClaw supervisor bridge, room manager, response generator`**

Fichiers : `src/agent-process.ts`, `src/agent-process.test.ts`,
`src/core-bridge.ts`, `src/quick-tunnel.ts`, `src/response-generator.ts`,
`src/response-generator.test.ts`, `src/room-manager.test.ts`

---

**3. `feat(stimm-voice): Python voice agent — LiveKit Agents v1 entrypoint, STT/TTS/LLM plugin support`**

Fichiers : `python/.gitignore`, `python/Dockerfile`, `python/agent.py`,
`python/requirements.txt`

---

**4. `fix(stimm-voice): WSL2/Docker WebRTC — LD_PRELOAD shim for Nvidia crashes, TCP+UDP port mapping, TURN credentials`**

Fichiers : `docker/docker-compose.dev.yml`, `docker/docker-compose.stimm.yml`,
`docker/livekit.yaml`, `python/lk_no_hw_video.c`

---

**5. `feat(stimm-voice): interactive setup wizard — multi-provider catalog (Deepgram, ElevenLabs, Hume, Groq, OpenAI)`**

Fichiers : `src/setup-wizard.ts`

---

**6. `feat(stimm-voice): web voice UI, claim-token flow, and CLI commands (voice:start, voice:logs, voice:setup)`**

Fichiers : `scripts/dev-setup.sh`, `src/cli.ts`, `src/cli.test.ts`,
`src/web/voice.html`

---

**7. `chore(stimm-voice): @stimm/protocol from npm 0.1.8`**

Fichier : `python/.gitignore` (ajout des entrées `.venv/`, `__pycache__/`, etc.)

---

**8. `fix(stimm-voice): address all Codex security and robustness review issues`**

Fusionne les 10 commits de fix itératifs Codex. Résumé des changements :

- `index.ts` : webhook auth enforce, supervisor auth toujours actif, nettoyage
  sessions orphelines, claim revocation, rate-limit par IP, stateless claim
  fallback, `purgeClaimsForRoom`, `emptyTimeout` sur `createRoom`, rollback room
  si dispatch échoue, rollback claim si `issueJoinToken` échoue, hasUnsafePublic-
  SupervisorSecret guard, tunnel validé avant création de session
- `src/agent-process.ts` : error handling sur spawn, `freePort` — filtre isSafe
  restreint aux identifiants Stimm/LiveKit (suppression du match générique `python`)
- `src/quick-tunnel.ts` : détection buffer tunnel, tunnel buffer timeout
- `src/setup-wizard.ts` : remplace `fetch()` brut par `fetchWithSsrFGuard`
- `src/web/voice.html` : fix mineur session guard
- `src/room-manager.test.ts` : tests pour teardown cross-process et rollback room
- `docker/`, `scripts/` : corrections config LiveKit, dev-setup

---

**9. `fix(stimm-voice): auto-close CLI when last human participant disconnects (room poller)`**

Fusionne 3 commits (`exit process after QR`, `keep CLI alive in quick-tunnel`,
`auto-close room poller`). Résumé :

- `src/cli.ts` : poller `setInterval` 15 s, filtre `stimm-supervisor-*`, seuil
  `EMPTY_THRESHOLD = 2` (≥ 30 s vide = fermeture auto)
- `index.ts` : expose `listRoomParticipants` sur `roomManager` (identité, kind,
  state) ; process.exit après affichage QR (évite fuite handles LiveKit)
- `src/cli.test.ts` : coverage poller et exit

---

**10. `chore(stimm-voice): scaffold as standalone third-party plugin`**

Fichiers : `package.json` (rename `openclaw-stimm-voice`, peerDeps, scripts),
`tsconfig.json` (standalone, sans paths monorepo), `.gitignore`,
`.github/workflows/ci.yml`, `README.md` (install depuis npm/GitHub)

---

### 2. Ajouter un `vitest.config.ts` à la racine

Le monorepo résout `openclaw/plugin-sdk` via un alias Vite pointant vers les
sources locales. En standalone, l'alias n'existe pas — mais ce n'est pas un
problème : aucun fichier de test n'importe `openclaw/plugin-sdk` directement
(ils mockent uniquement `livekit-server-sdk`). Un config minimal suffit :

```ts
// vitest.config.ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    pool: "forks",
    testTimeout: 30_000,
  },
});
```

---

### 3. Ajouter un `.npmignore`

Pour éviter de publier les fichiers de dev sur npm :

```
# .npmignore
src/**/*.test.ts
.github/
*.config.ts
python/.venv/
docker/
```

---

### 4. Workflow `release-please` (releases automatisées)

Crée `.github/workflows/release-please.yml` :

```yaml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.rp.outputs.release_created }}
      tag_name: ${{ steps.rp.outputs.tag_name }}
    steps:
      - uses: googleapis/release-please-action@v4
        id: rp
        with:
          release-type: node

  publish:
    needs: release-please
    if: needs.release-please.outputs.release_created == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 22
          registry-url: https://registry.npmjs.org

      - run: npm ci

      - run: npm publish --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

Ajouter le secret `NPM_TOKEN` dans les settings du repo GitHub
(Settings → Secrets → Actions → New repository secret).

`release-please` utilise les **Conventional Commits** pour bumper la version et
générer le `CHANGELOG.md`. Format de commit attendu :

```
fix(stimm-voice): <description>   → patch bump
feat(stimm-voice): <description>  → minor bump
feat!: <description>               → major bump
```

> **Note version** : `release-please` gère le format `semver` standard (`1.2.3`).
> Le format calver `2026.2.20` en cours est valide mais `release-please` en mode
> `node` va le bumper comme `2026.2.21` etc. C'est acceptable ; si tu veux rester
> sur du calver pur, configure `release-type: simple` + un `version.txt`.

---

### 5. Vérifier l'import par openclaw (`npm install` froid)

Le plugin est chargé par openclaw via `jiti` (transpilation à la volée des `.ts`).
La clé dans `package.json` est :

```json
"openclaw": {
  "extensions": ["./index.ts"]
}
```

Pour tester qu'un `openclaw plugins install openclaw-stimm-voice` fonctionne :

```bash
# dans un dossier vide séparé
mkdir test-install && cd test-install
npm init -y
npm install openclaw  # (ou utilise un openclaw gateway déjà installé)
openclaw plugins install openclaw-stimm-voice
openclaw gateway start
openclaw voice:status
```

Points de blocage potentiels :
- `@stimm/protocol` doit être accessible sur le registry npm (vérifie `npm view @stimm/protocol`).
- `@livekit/rtc-node` a des binaires natifs — vérifie que le `postinstall` passe bien en CI Ubuntu.

---

### 6. PR sur la page community plugins d'openclaw

Une fois le package publié sur npm :

1. Fork `openclaw/openclaw`.
2. Édite `docs/plugins/community.mdx` (ou le fichier équivalent dans `docs/plugins/`) :
   ```md
   ## Voice
   
   ### openclaw-stimm-voice
   Real-time voice sessions powered by Stimm dual-agent architecture (LiveKit + STT/TTS/LLM).
   - npm: `openclaw-stimm-voice`
   - Repo: https://github.com/EtienneLescot/openclaw-stimm-voice
   - Author: [@EtienneLescot](https://github.com/EtienneLescot)
   ```
3. Ouvre une PR vers `openclaw/openclaw` avec le label `documentation`.

---

## Ordre des opérations recommandé

```
1. Créer le repo GitHub
2. Copier le contenu + push sur main
3. Ajouter vitest.config.ts + .npmignore + release-please workflow
4. Configurer NPM_TOKEN dans les secrets GitHub
5. Push → release-please va ouvrir une PR de release automatiquement
6. Merger la PR de release → déclenche le publish npm
7. Vérifier : npm view openclaw-stimm-voice
8. Tester l'install depuis openclaw
9. Ouvrir la PR community plugins
```

---

## Fichiers déjà prêts (dans extensions/stimm-voice/)

| Fichier | État |
|---|---|
| `package.json` | ✅ name=`openclaw-stimm-voice`, peerDeps, scripts |
| `tsconfig.json` | ✅ standalone (sans paths monorepo) |
| `.gitignore` | ✅ |
| `.github/workflows/ci.yml` | ✅ typecheck + test sur push/PR |
| `README.md` | ✅ install depuis npm + GitHub |
| `release-please workflow` | ❌ à créer |
| `vitest.config.ts` | ❌ à créer |
| `.npmignore` | ❌ à créer |
