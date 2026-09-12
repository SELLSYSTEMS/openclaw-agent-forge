import { createReadStream } from "node:fs";
import { readFile, realpath } from "node:fs/promises";
import path from "node:path";
import { createInterface } from "node:readline";
import { fileURLToPath, pathToFileURL } from "node:url";

export async function summarizeTranscript(lines) {
  const result = {
    state: "no_turn",
    error_class: null,
    last_user_record_at: null,
    last_assistant_record_at: null,
    malformed_records: 0,
  };
  for await (const line of lines) {
    if (!line.trim()) continue;
    let record;
    try {
      record = JSON.parse(line);
    } catch {
      result.malformed_records++;
      continue;
    }
    if (record?.type !== "message") continue;
    const message = record.message;
    if (message?.role === "user") {
      result.last_user_record_at = record.timestamp ?? null;
      result.state = "awaiting_or_interrupted";
      result.error_class = null;
    } else if (message?.role === "assistant") {
      result.last_assistant_record_at = record.timestamp ?? null;
      result.error_class = null;
      if (message.stopReason === "error") {
        result.state = "failed";
        const error = typeof message.errorMessage === "string" ? message.errorMessage : "";
        result.error_class = /usage.limit|quota.exceeded|insufficient_quota/i.test(error)
          ? "provider_usage_limit" : "runtime_error";
      } else if (["stop", "end_turn"].includes(message.stopReason)) {
        result.state = "completed";
      } else {
        result.state = "awaiting_or_interrupted";
      }
    }
  }
  if (result.malformed_records) result.state = "unknown_malformed_transcript";
  return result;
}

async function main() {
  const root = fileURLToPath(new URL("../", import.meta.url));
  const state = path.join(process.env.OPENCLAW_HOME ?? path.join(root, ".openclaw-home"), ".openclaw");
  const key = process.env.OPENCLAW_SESSION_KEY ?? "agent:main:main";
  const sessions = JSON.parse(await readFile(path.join(state, "agents/main/sessions/sessions.json"), "utf8"));
  if (!sessions[key]?.sessionFile) throw new Error("Session transcript is not configured");
  const file = await realpath(sessions[key].sessionFile);
  const agents = await realpath(path.join(state, "agents"));
  if (!file.startsWith(agents + path.sep)) throw new Error("Transcript is outside the isolated agents root");
  const input = createReadStream(file, { encoding: "utf8" });
  const lines = createInterface({ input, crlfDelay: Infinity });
  try {
    const result = await summarizeTranscript(lines);
    console.log(JSON.stringify({
      ...result,
      evidence: "OpenClaw transcript only; verify native Codex events and live processes separately",
    }, null, 2));
  } finally {
    lines.close();
    input.destroy();
  }
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  await main();
}
