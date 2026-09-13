import { readFileSync, writeFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../", import.meta.url));
export const botName = "bot-BJJHvk3V.js";
export const stockHash = "63286458369fb7291b86dfa4e80522ff008572772566a1006a3ba89e9d878afd";
export const managedHash = "c5c573f6467430ca63e5cc93782f074b59e977c4460e142b4b0a070d39fb4987";
export const patchPath = path.join(root, "patches/openclaw-2026.4.12-telegram-outbox.patch");
export const hash = (source) => createHash("sha256").update(source).digest("hex");

// Apply only exact, counted unified hunks. No fuzzy matching or external patch command.
export function applyUnifiedDiff(source, patchText) {
  if (!source.endsWith("\n")) throw new Error("Expected newline-terminated runtime source");
  const lines = source.slice(0, -1).split("\n");
  const diff = patchText.trimEnd().split("\n");
  const output = [];
  let cursor = 0;
  let hunks = 0;
  for (let i = 0; i < diff.length; i++) {
    const header = /^@@ -(\d+),(\d+) \+(\d+),(\d+) @@/.exec(diff[i]);
    if (!header) {
      if (i < 2 && /^(---|\+\+\+) /.test(diff[i])) continue;
      throw new Error(`Unexpected unified diff line ${i + 1}`);
    }
    const [, oldStart, oldCount, newStart, newCount] = header.map(Number);
    if (oldStart - 1 < cursor) throw new Error("Overlapping patch hunks");
    output.push(...lines.slice(cursor, oldStart - 1));
    cursor = oldStart - 1;
    if (output.length !== newStart - 1) throw new Error("Patch output position mismatch");
    let consumed = 0;
    let produced = 0;
    while (i + 1 < diff.length && !diff[i + 1].startsWith("@@ ")) {
      const line = diff[++i];
      const kind = line[0];
      const text = line.slice(1);
      if (![" ", "+", "-"].includes(kind)) throw new Error("Malformed patch hunk");
      if (kind !== "+") {
        if (lines[cursor++] !== text) throw new Error("Patch source context mismatch");
        consumed++;
      }
      if (kind !== "-") {
        output.push(text);
        produced++;
      }
    }
    if (consumed !== oldCount || produced !== newCount) throw new Error("Patch hunk count mismatch");
    hunks++;
  }
  if (!hunks) throw new Error("Patch contains no hunks");
  return [...output, ...lines.slice(cursor)].join("\n") + "\n";
}

function main() {
  const dist = process.env.OPENCLAW_TEST_DIST ?? path.join(root, ".openclaw/lib/node_modules/openclaw/dist");
  const version = JSON.parse(readFileSync(path.join(dist, "../package.json"), "utf8")).version;
  if (version !== "2026.4.12") throw new Error(`Unvalidated Telegram outbox runtime ${version}`);
  const file = path.join(dist, botName);
  const source = readFileSync(file, "utf8");
  const currentHash = hash(source);
  if (currentHash === managedHash) {
    console.log("Telegram outbox base and generic-failure guard verified; file unchanged");
    return;
  }
  if (currentHash !== stockHash) throw new Error("Unknown Telegram bot bytes; refusing to overwrite local changes");
  if (process.argv.includes("--check")) throw new Error("Missing Telegram outbox base; apply the runtime patches first");
  const next = applyUnifiedDiff(source, readFileSync(patchPath, "utf8"));
  if (hash(next) !== managedHash) throw new Error("Telegram outbox patch result hash mismatch");
  const syntax = spawnSync(process.execPath, ["--input-type=module", "--check"], { input: next, encoding: "utf8" });
  if (syntax.status !== 0) throw new Error(`Invalid Telegram outbox syntax: ${syntax.stderr}`);
  writeFileSync(file, next);
  console.log("Telegram outbox base and generic-failure guard applied to verified stock runtime");
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
