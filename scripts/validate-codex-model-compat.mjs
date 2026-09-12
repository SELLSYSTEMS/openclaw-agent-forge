import assert from "node:assert/strict";
import { readFile, readdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import vm from "node:vm";

const dist = new URL("../.openclaw/lib/node_modules/openclaw/dist/", import.meta.url);
const { buildCodexProvider } = await import(new URL("extensions/codex/provider.js", dist));
const provider = buildCodexProvider();
const modelId = "gpt-6-astra";
const model = provider.resolveDynamicModel({ modelId });

// Test offline resolution: a successful live model/list alone missed this regression.
assert.equal(model.id, modelId);
assert.equal(model.provider, "codex");
assert.equal(model.reasoning, true, "Astra must remain a reasoning model without discovery");
assert.equal(model.compat.supportsReasoningEffort, true);
assert.equal(provider.supportsXHighThinking({ modelId }), true);
assert.equal(provider.isModernModelRef({ modelId }), true);
assert.equal(provider.resolveDynamicModel({ modelId: "gpt-5.6-sol" }).reasoning, true);
assert.equal(provider.resolveDynamicModel({ modelId: "unknown-future-model" }).reasoning, false);

const harnessFiles = (await readdir(dist)).filter((name) => /^harness-.*\.js$/.test(name));
let bridgeChecked = false;
for (const name of harnessFiles) {
  const source = await readFile(new URL(name, dist), "utf8");
  const match = source.match(/function resolveReasoningEffort\(thinkLevel\) \{[^}]*\}/);
  if (!match) continue;
  const resolveEffort = vm.runInNewContext(`(${match[0]})`, {}, { timeout: 1000 });
  assert.equal(resolveEffort("max"), "max", "Codex turn/start must receive max unchanged");
  assert.equal(resolveEffort("xhigh"), "xhigh");
  assert.match(source, /effort: resolveReasoningEffort\(params\.thinkLevel\)/);
  bridgeChecked = true;
}
assert.ok(bridgeChecked, `Unable to validate Codex reasoning bridge in ${fileURLToPath(dist)}`);
console.log("Codex model compatibility validated: Astra offline reasoning and max bridge.");
