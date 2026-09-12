import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtemp, mkdir, readFile, rm, stat, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const script = fileURLToPath(new URL("./backup-openclaw-continuity-state.sh", import.meta.url));
const thread = "00000000-0000-0000-0000-000000000001";

async function fixture(run, { sidecar = true, native = true } = {}) {
  const root = await mkdtemp(path.join(os.tmpdir(), "openclaw backup test-"));
  try {
    const home = path.join(root, "runtime");
    const sessions = path.join(home, ".openclaw/agents/main/sessions");
    const codex = path.join(root, "codex");
    const workspace = path.join(root, "workspace");
    for (const dir of [sessions, path.join(codex, "sessions"), path.join(workspace, "memory")]) {
      await mkdir(dir, { recursive: true });
    }
    const json = (file, value) => writeFile(file, JSON.stringify(value) + "\n");
    const transcript = path.join(sessions, "example.jsonl");
    await writeFile(transcript, '{"type":"session"}\n');
    await json(path.join(home, ".openclaw/openclaw.json"), { agents: { defaults: { workspace } } });
    await json(path.join(sessions, "sessions.json"), { "agent:main:main": { sessionId: "example", sessionFile: transcript } });
    if (sidecar) await json(transcript + ".codex-app-server.json", { threadId: thread });
    if (native) await json(path.join(codex, "sessions", `rollout-example-${thread}.jsonl`), { type: "session_meta", payload: { id: thread } });
    await writeFile(path.join(workspace, "memory/checkpoint.md"), "Fixture checkpoint\n");
    const backup = path.join(root, "backup");
    const execute = () => execFileSync("bash", [script], {
      env: { ...process.env, OPENCLAW_HOME: home, CODEX_HOME: codex, OPENCLAW_BACKUP_DIR: backup, OPENCLAW_SESSION_KEY: "agent:main:main" },
      encoding: "utf8", stdio: "pipe",
    });
    await run({ root, backup, execute, transcript });
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

test("full backup includes native history, memory, private permissions and valid checksums", () => fixture(async ({ backup, execute }) => {
  assert.match(execute(), /native_codex_rollout=present/);
  assert.equal((await stat(backup)).mode & 0o777, 0o700);
  assert.equal((await stat(path.join(backup, "codex-rollout.jsonl"))).mode & 0o777, 0o600);
  assert.match(await readFile(path.join(backup, "codex-rollout.jsonl"), "utf8"), /session_meta/);
  assert.match(execFileSync("tar", ["-tzf", path.join(backup, "workspace-memory.tar.gz")], { encoding: "utf8" }), /memory\/checkpoint.md/);
  execFileSync("sha256sum", ["-c", "SHA256SUMS"], { cwd: backup, stdio: "pipe" });
  assert.throws(execute, /Refusing to overwrite/);
}));

test("missing bound native history blocks incomplete backups", () => fixture(async ({ execute }) => {
  assert.throws(execute, /Expected one native Codex rollout/);
}, { native: false }));

test("a session without a Codex binding can still be backed up", () => fixture(async ({ execute }) => {
  assert.match(execute(), /native_codex_rollout=absent/);
}, { sidecar: false, native: false }));

test("out-of-tree transcript is rejected", () => fixture(async ({ execute, transcript, root }) => {
  const file = path.join(path.dirname(transcript), "sessions.json");
  const outside = path.join(root, "outside.jsonl");
  await writeFile(outside, "fixture\n");
  await writeFile(file, JSON.stringify({ "agent:main:main": { sessionId: "example", sessionFile: outside } }));
  assert.throws(execute, /out-of-tree session file/);
}));
