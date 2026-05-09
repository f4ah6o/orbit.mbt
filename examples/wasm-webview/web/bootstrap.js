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
    const html = exports.get_html();
    document.getElementById("app").innerHTML = html;
  } catch (e) {
    document.getElementById("app").innerHTML = `<p class="error">render error: ${e}</p>`;
    logEvent(`render error: ${e.message || e}`);
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
  logEvent("initial render done");
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
