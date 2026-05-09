///|
fn echo_metadata() -> @orbit.ToolMetadata {
  {
    name: "echo",
    description: "Echoes the input back as output",
    permissions: [],
    version: "1.0.0",
  }
}

///|
fn echo_execute(input : String) -> @orbit.ExecResult {
  @orbit.ExecResult::ok(input)
}

///|
fn clock_metadata() -> @orbit.ToolMetadata {
  {
    name: "clock",
    description: "Returns a fixed timestamp",
    permissions: [],
    version: "1.0.0",
  }
}

///|
fn clock_execute(_input : String) -> @orbit.ExecResult {
  @orbit.ExecResult::ok("2026-05-09T12:00:00Z")
}

///|
fn add_metadata() -> @orbit.ToolMetadata {
  {
    name: "add",
    description: "Adds two comma-separated numbers",
    permissions: [],
    version: "1.0.0",
  }
}

///|
fn add_execute(input : String) -> @orbit.ExecResult {
  let parts = input.split(",").to_array()
  if parts.length() != 2 {
    return @orbit.ExecResult::fail(
      "invalid input: expected two comma-separated numbers",
    )
  }
  let a_view = parts[0].trim()
  let b_view = parts[1].trim()
  let a : Int = @strconv.from_str(a_view) catch {
    _ =>
      return @orbit.ExecResult::fail(
        "invalid input: both values must be integers",
      )
  }
  let b : Int = @strconv.from_str(b_view) catch {
    _ =>
      return @orbit.ExecResult::fail(
        "invalid input: both values must be integers",
      )
  }
  @orbit.ExecResult::ok((a + b).to_string())
}

///|
struct EchoTool {
}

///|
impl @orbit.Tool for EchoTool with metadata(self) -> @orbit.ToolMetadata {
  ignore(self)
  echo_metadata()
}

///|
impl @orbit.Tool for EchoTool with execute(self, input : String) -> @orbit.ExecResult {
  ignore(self)
  echo_execute(input)
}

///|
struct ClockTool {
}

///|
impl @orbit.Tool for ClockTool with metadata(self) -> @orbit.ToolMetadata {
  ignore(self)
  clock_metadata()
}

///|
impl @orbit.Tool for ClockTool with execute(self, input : String) -> @orbit.ExecResult {
  ignore(self)
  clock_execute(input)
}

///|
struct AddTool {
}

///|
impl @orbit.Tool for AddTool with metadata(self) -> @orbit.ToolMetadata {
  ignore(self)
  add_metadata()
}

///|
impl @orbit.Tool for AddTool with execute(self, input : String) -> @orbit.ExecResult {
  ignore(self)
  add_execute(input)
}

///|
pub fn register_tools(reg : @orbit.ToolRegistry) -> Unit {
  reg.register_tool(EchoTool::{})
  reg.register_tool(ClockTool::{})
  reg.register_tool(AddTool::{})
}
