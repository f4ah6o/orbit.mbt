///|
fn js_emit_html(_html : String) -> Unit {
  ()
}

///|
struct DemoReadTool {}

///|
impl @orbit.Tool for DemoReadTool with metadata(_self) -> @orbit.ToolMetadata {
  {
    name: "demo.read",
    description: "Demo-only read tool used to exercise the App Server approval boundary.",
    permissions: [@orbit.FileRead("/demo/session.txt")],
    version: "1",
  }
}

///|
impl @orbit.Tool for DemoReadTool with execute(_self, input) -> @orbit.ExecResult {
  @orbit.ExecResult::ok("demo.read(" + input + ")")
}

///|
let current_session : Ref[@orbit.Session] = {
  val: @orbit.Session::create("demo"),
}

///|
let call_counter : Ref[Int] = { val: 0 }

///|
let last_call_id : Ref[String] = { val: "" }

///|
let demo_registry_ref : Ref[@orbit.ToolRegistry?] = { val: None }

///|
fn main {
  boot()
}

///|
fn demo_registry() -> @orbit.ToolRegistry {
  match demo_registry_ref.val {
    Some(registry) => registry
    None => {
      let registry = @orbit.ToolRegistry::create()
      registry.register_tool(DemoReadTool::{  })
      demo_registry_ref.val = Some(registry)
      registry
    }
  }
}

///|
fn payload_or(payload : String, fallback : String) -> String {
  if payload == "" {
    fallback
  } else {
    payload
  }
}

///|
fn apply_session_tool(
  name : String,
  input : @orbit.AppServerSessionToolInput,
) -> Unit {
  match current_session.val.apply_app_server_session_tool(name, input) {
    Ok(s) => current_session.val = s
    Err(msg) => current_session.val = current_session.val.fail(msg)
  }
  re_render()
}

///|
pub fn boot() -> Unit {
  // Start from Idle; let the user click "Start" to transition to Running.
  re_render()
}

///|
pub fn reset_demo() -> Unit {
  current_session.val = @orbit.Session::create("demo")
  call_counter.val = 0
  last_call_id.val = ""
  re_render()
}

///|
pub fn dispatch_event(kind : String, payload : String) -> Unit {
  match kind {
    "start" => apply_session_tool("start_session", @orbit.EmptyInput)
    "end" => apply_session_tool("end_session", @orbit.EmptyInput)
    "user_message" =>
      apply_session_tool(
        "append_user_message",
        @orbit.TextInput(payload_or(payload, "hello from WebView")),
      )
    "request_tool" => {
      call_counter.val = call_counter.val + 1
      let call_id = "call-" + call_counter.val.to_string()
      last_call_id.val = call_id
      // This reference client intentionally models one approval-required host
      // tool; custom payloads are labels only when adapters experiment with UI.
      let req : @orbit.ToolRequest = {
        tool_name: "demo.read",
        input: "{\"path\":\"/demo/session.txt\"}",
        call_id,
      }
      apply_session_tool("record_tool_request", @orbit.ToolRequestInput(req))
    }
    "respond_tool" => {
      let res : @orbit.ToolResponse = {
        call_id: last_call_id.val,
        output: payload_or(payload, "demo result"),
        success: true,
      }
      apply_session_tool("record_tool_result", @orbit.ToolResponseInput(res))
    }
    _ => ()
  }
}

///|
pub fn get_html() -> String {
  get_resource_html()
}

///|
pub fn get_resource_html() -> String {
  @orbit.render_resource(@orbit.project(current_session.val))
}

///|
pub fn get_resource_json() -> String {
  @orbit.project(current_session.val).to_json_string()
}

///|
pub fn get_snapshot_json() -> String {
  current_session.val.app_server_snapshot_json(demo_registry(), [])
}

///|
pub fn get_session_tool_catalog_json() -> String {
  @orbit.app_server_session_tool_catalog_json()
}

///|
pub fn get_execute_tool_plan_json() -> String {
  @orbit.plan_app_server_session_tool(
    current_session.val,
    demo_registry(),
    [],
    "execute_tool_request",
  ).to_json_string()
}

///|
pub fn get_replay_export_json() -> String {
  current_session.val.app_server_replay_export_json(demo_registry(), [])
}

///|
fn re_render() -> Unit {
  let html = get_resource_html()
  js_emit_html(html)
}
