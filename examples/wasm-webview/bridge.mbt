///|
fn js_emit_html(_html : String) -> Unit {
  ()
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
fn main {
  boot()
}

///|
pub fn boot() -> Unit {
  // Start from Idle; let the user click "Start" to transition to Running.
  re_render()
}

///|
pub fn dispatch_event(kind : String, payload : String) -> Unit {
  match kind {
    "start" =>
      match current_session.val.start() {
        Ok(s) => {
          current_session.val = s
          re_render()
        }
        Err(msg) => {
          current_session.val = current_session.val.fail(msg)
          re_render()
        }
      }
    "end" =>
      match current_session.val.end() {
        Ok(s) => {
          current_session.val = s
          re_render()
        }
        Err(msg) => {
          current_session.val = current_session.val.fail(msg)
          re_render()
        }
      }
    "user_message" =>
      match current_session.val.send_user_message(payload) {
        Ok(s) => {
          current_session.val = s
          re_render()
        }
        Err(msg) => {
          current_session.val = current_session.val.fail(msg)
          re_render()
        }
      }
    "request_tool" => {
      call_counter.val = call_counter.val + 1
      let call_id = "call-" + call_counter.val.to_string()
      last_call_id.val = call_id
      let req : @orbit.ToolRequest = { tool_name: payload, input: "", call_id }
      match current_session.val.request_tool(req) {
        Ok(s) => {
          current_session.val = s
          re_render()
        }
        Err(msg) => {
          current_session.val = current_session.val.fail(msg)
          re_render()
        }
      }
    }
    "respond_tool" => {
      let res : @orbit.ToolResponse = {
        call_id: last_call_id.val,
        output: payload,
        success: true,
      }
      match current_session.val.respond_tool(res) {
        Ok(s) => {
          current_session.val = s
          re_render()
        }
        Err(msg) => {
          current_session.val = current_session.val.fail(msg)
          re_render()
        }
      }
    }
    _ => ()
  }
}

///|
pub fn get_html() -> String {
  @orbit.session_viewer(current_session.val)
}

///|
fn re_render() -> Unit {
  let html = get_html()
  js_emit_html(html)
}
