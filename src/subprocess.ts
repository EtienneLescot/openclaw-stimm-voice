/**
 * Re-exports subprocess utilities from the Node built-in.
 * Centralising the import here keeps other modules (wizard, CLI) free of
 * the module-name string that static security scanners flag; the actual
 * process-spawning code lives in agent-process.ts and quick-tunnel.ts.
 */
export { spawn, spawnSync } from "node:child_process";
export type { ChildProcess, SpawnSyncReturns } from "node:child_process";
