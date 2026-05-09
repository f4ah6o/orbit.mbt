///|
fn main {
  let reg = @orbit.ToolRegistry::create()
  register_tools(reg)

  run_echo_scenario(reg)
  run_clock_scenario(reg)
  run_add_scenario(reg)
  run_add_error_scenario(reg)
}

///|
fn state_label(session : @orbit.Session) -> String {
  if session.is_idle() {
    "Idle"
  } else if session.is_running() {
    "Running"
  } else if session.is_waiting_tool() {
    "WaitingTool"
  } else if session.is_failed() {
    "Failed"
  } else {
    "Unknown"
  }
}

///|
fn run_echo_scenario(reg : @orbit.ToolRegistry) -> Unit {
  println("=== Echo Scenario ===")
  match run_echo(reg) {
    Ok(s) => {
      println("event_count: " + s.event_count().to_string())
      println("final state: " + state_label(s))
    }
    Err(e) => println("error: " + e)
  }
  println("")
}

///|
fn run_echo(reg : @orbit.ToolRegistry) -> Result[@orbit.Session, String] {
  let session = @orbit.Session::create("echo-scenario").start().unwrap()
  let session = session.send_user_message("hello").unwrap()
  let req : @orbit.ToolRequest = {
    tool_name: "echo",
    input: "hello",
    call_id: "c1",
  }
  let session = session.request_tool(req).unwrap()
  let session = step(session, reg)
  let session = session.receive_assistant_message("Echo: hello").unwrap()
  Ok(session.end().unwrap())
}

///|
fn run_clock_scenario(reg : @orbit.ToolRegistry) -> Unit {
  println("=== Clock Scenario ===")
  match run_clock(reg) {
    Ok(s) => {
      println("event_count: " + s.event_count().to_string())
      println("final state: " + state_label(s))
    }
    Err(e) => println("error: " + e)
  }
  println("")
}

///|
fn run_clock(reg : @orbit.ToolRegistry) -> Result[@orbit.Session, String] {
  let session = @orbit.Session::create("clock-scenario").start().unwrap()
  let req : @orbit.ToolRequest = {
    tool_name: "clock",
    input: "",
    call_id: "c1",
  }
  let session = session.request_tool(req).unwrap()
  let session = step(session, reg)
  let session = session
    .receive_assistant_message("2026-05-09T12:00:00Z")
    .unwrap()
  Ok(session.end().unwrap())
}

///|
fn run_add_scenario(reg : @orbit.ToolRegistry) -> Unit {
  println("=== Add Scenario ===")
  match run_add(reg) {
    Ok(s) => {
      println("event_count: " + s.event_count().to_string())
      println("final state: " + state_label(s))
    }
    Err(e) => println("error: " + e)
  }
  println("")
}

///|
fn run_add(reg : @orbit.ToolRegistry) -> Result[@orbit.Session, String] {
  let session = @orbit.Session::create("add-scenario").start().unwrap()
  let req : @orbit.ToolRequest = {
    tool_name: "add",
    input: "3,4",
    call_id: "c1",
  }
  let session = session.request_tool(req).unwrap()
  let session = step(session, reg)
  let session = session.receive_assistant_message("7").unwrap()
  Ok(session.end().unwrap())
}

///|
fn run_add_error_scenario(reg : @orbit.ToolRegistry) -> Unit {
  println("=== Add Error Scenario ===")
  match run_add_error(reg) {
    Ok(s) => {
      println("event_count: " + s.event_count().to_string())
      println("final state: " + state_label(s))
    }
    Err(e) => println("error: " + e)
  }
  println("")
}

///|
fn run_add_error(
  reg : @orbit.ToolRegistry,
) -> Result[@orbit.Session, String] {
  let session = @orbit.Session::create("add-error-scenario").start().unwrap()
  let req : @orbit.ToolRequest = {
    tool_name: "add",
    input: "bad",
    call_id: "c1",
  }
  let session = session.request_tool(req).unwrap()
  let session = step(session, reg)
  let session = session
    .receive_assistant_message("Error: invalid input")
    .unwrap()
  Ok(session.end().unwrap())
}
