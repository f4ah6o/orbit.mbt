const WASM_URL = "wasm-webview.wasm";

let exports = null;
const logEntries = [];

function logEvent(text) {
  const now = new Date().toLocaleTimeString();
  logEntries.push(`[${now}] ${text}`);
  const list = document.getElementById("log-list");
  const li = document.createElement("li");
  li.textContent = logEntries[logEntries.length - 1];
  list.appendChild(li);
}

function updateApp() {
  if (!exports) return;
  try {
    const html = exports.get_resource_html();
    document.getElementById("app").innerHTML = html;
    setJson("snapshot-json", exports.get_snapshot_json());
    setJson("resource-json", exports.get_resource_json());
    setJson("tool-catalog-json", exports.get_session_tool_catalog_json());
    setJson("tool-plan-json", exports.get_execute_tool_plan_json());
    setJson("replay-json", exports.get_replay_export_json());
  } catch (e) {
    document.getElementById("app").innerHTML = `<p class="error">render error: ${e}</p>`;
    logEvent(`render error: ${e.message || e}`);
  }
}

function setJson(id, json) {
  const node = document.getElementById(id);
  try {
    node.textContent = JSON.stringify(JSON.parse(json), null, 2);
  } catch (_e) {
    node.textContent = json;
  }
}

function getPayload() {
  return document.getElementById("payload-input").value || "";
}

async function init() {
  const imports = {
    orbit: {
      emit_html: (html) => {
        document.getElementById("app").innerHTML = html;
      }
    }
  };

  const wasm = await WebAssembly.instantiateStreaming(fetch(WASM_URL), imports);
  exports = wasm.instance.exports;

  logEvent("wasm module loaded");

  exports.boot();
  logEvent("boot() called");

  updateApp();
  logEvent("initial snapshot/render/action/replay artifacts loaded");
}

document.getElementById("btn-start").addEventListener("click", () => {
  if (!exports) return;
  exports.dispatch_event("start", getPayload());
  updateApp();
  logEvent("dispatch_event: start");
});

document.getElementById("btn-end").addEventListener("click", () => {
  if (!exports) return;
  exports.dispatch_event("end", getPayload());
  updateApp();
  logEvent("dispatch_event: end");
});

document.getElementById("btn-user-msg").addEventListener("click", () => {
  if (!exports) return;
  exports.dispatch_event("user_message", getPayload());
  updateApp();
  logEvent(`dispatch_event: user_message "${getPayload()}"`);
});

document.getElementById("btn-request-tool").addEventListener("click", () => {
  if (!exports) return;
  exports.dispatch_event("request_tool", getPayload());
  updateApp();
  logEvent(`dispatch_event: request_tool "${getPayload()}"`);
});

document.getElementById("btn-respond-tool").addEventListener("click", () => {
  if (!exports) return;
  exports.dispatch_event("respond_tool", getPayload());
  updateApp();
  logEvent(`dispatch_event: respond_tool "${getPayload()}"`);
});

init().catch((e) => {
  document.getElementById("app").innerHTML = `<p class="error">failed to load wasm: ${e}</p>`;
  logEvent(`wasm load error: ${e.message || e}`);
});
