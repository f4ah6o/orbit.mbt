///|
/// A simple echo tool for testing — returns the input unchanged.
struct EchoTool {
  name : String
} derive(Debug, Eq)

///|
impl Tool for EchoTool with metadata(self) -> ToolMetadata {
  {
    name: self.name,
    description: "Echoes the input back as output",
    permissions: [],
    version: "1.0.0",
  }
}

///|
impl Tool for EchoTool with execute(self, input : String) -> ExecResult {
  ExecResult::ok(input)
}

///|
/// A tool that always fails — for testing error handling.
struct FailTool {
  name : String
  error_message : String
} derive(Debug, Eq)

///|
impl Tool for FailTool with metadata(self) -> ToolMetadata {
  {
    name: self.name,
    description: "Always fails with a configured error message",
    permissions: [ShellExec("*")],
    version: "1.0.0",
  }
}

///|
impl Tool for FailTool with execute(self, _input : String) -> ExecResult {
  ExecResult::fail(self.error_message)
}

///|
/// A tool that requires FileRead permission.
struct FileReaderTool {} derive(Debug, Eq)

///|
impl Tool for FileReaderTool with metadata(self) -> ToolMetadata {
  {
    name: "read_file",
    description: "Reads a file from the filesystem",
    permissions: [FileRead("/tmp")],
    version: "1.0.0",
  }
}

///|
impl Tool for FileReaderTool with execute(self, input : String) -> ExecResult {
  ExecResult::ok("contents of " + input)
}

///|
test "permission equality and matching" {
  let p1 = FileRead("/tmp")
  let p2 = FileRead("/tmp")
  let p3 = FileRead("/etc")
  assert_eq(p1, p2)
  assert_true(p1 != p3)
}

///|
test "permission wildcard matching" {
  let required = FileRead("/tmp")
  let wildcard = FileRead("*")
  assert_true(permission_granted(required, [wildcard]))
  assert_true(permission_granted(required, [FileRead("/tmp")]))
  assert_true(!permission_granted(required, [FileRead("/etc")]))
  assert_true(!permission_granted(required, [ShellExec("/tmp")]))
}

///|
test "permissions_satisfied" {
  let required = [FileRead("/tmp"), FileWrite("/tmp")]
  let granted = [FileRead("*"), FileWrite("*")]
  assert_true(permissions_satisfied(required, granted))

  let partial : Array[Permission] = [FileRead("*")]
  assert_true(!permissions_satisfied(required, partial))
}

///|
test "exec result constructors" {
  let ok_result = ExecResult::ok("hello")
  assert_eq(ok_result.output, "hello")
  assert_eq(ok_result.success, true)
  assert_eq(ok_result.error, "")

  let fail_result = ExecResult::fail("oops")
  assert_eq(fail_result.output, "")
  assert_eq(fail_result.success, false)
  assert_eq(fail_result.error, "oops")
}

///|
test "lifecycle: Requested -> Approved -> Executing -> Completed" {
  let req = { tool_name: "echo", input: "hi", call_id: "c1" }
  let lc = ToolLifecycle::requested(req)

  assert_true(lc.is_requested())
  assert_true(!lc.is_terminal())

  let approved = lc.approve([FileRead("*")]).unwrap()
  assert_true(approved.is_approved())

  let executing = approved.start_executing().unwrap()
  assert_true(executing.is_executing())

  let result = ExecResult::ok("hi")
  let completed = executing.complete(result).unwrap()
  assert_true(completed.is_completed())
  assert_true(completed.is_terminal())
}

///|
test "lifecycle: Executing -> Failed" {
  let req = { tool_name: "echo", input: "hi", call_id: "c1" }
  let lc = ToolLifecycle::requested(req)
    .approve([])
    .unwrap()
    .start_executing()
    .unwrap()
    .fail("timeout")

  assert_true(lc.is_failed())
  assert_true(lc.is_terminal())
}

///|
test "lifecycle: invalid transitions are rejected" {
  let req = { tool_name: "echo", input: "hi", call_id: "c1" }

  let approved = ToolLifecycle::requested(req).approve([]).unwrap()
  assert_true(approved.start_executing().unwrap().start_executing() is Err(_))

  let completed = approved
    .start_executing()
    .unwrap()
    .complete(ExecResult::ok("ok"))
    .unwrap()
  assert_true(completed.approve([]) is Err(_))
  assert_true(completed.start_executing() is Err(_))
  assert_true(completed.complete(ExecResult::ok("x")) is Err(_))
}

///|
test "lifecycle: fail from any active state" {
  let req = { tool_name: "echo", input: "hi", call_id: "c1" }
  let failed_from_requested = ToolLifecycle::requested(req).fail("err")
  assert_true(failed_from_requested.is_failed())
  assert_true(failed_from_requested.is_terminal())

  let failed_from_approved = ToolLifecycle::requested(req)
    .approve([])
    .unwrap()
    .fail("err")
  assert_true(failed_from_approved.is_failed())

  let failed_from_executing = ToolLifecycle::requested(req)
    .approve([])
    .unwrap()
    .start_executing()
    .unwrap()
    .fail("err")
  assert_true(failed_from_executing.is_failed())
}

///|
test "lifecycle: fail is idempotent on terminal states" {
  let req = { tool_name: "echo", input: "hi", call_id: "c1" }
  let completed = ToolLifecycle::requested(req)
    .approve([])
    .unwrap()
    .start_executing()
    .unwrap()
    .complete(ExecResult::ok("ok"))
    .unwrap()
  let still_completed = completed.fail("ignored")
  assert_true(still_completed.is_completed())

  let failed = ToolLifecycle::requested(req).fail("first")
  let still_failed = failed.fail("second")
  assert_true(still_failed.is_failed())
}

///|
test "lifecycle: request accessor" {
  let req = { tool_name: "echo", input: "hi", call_id: "c1" }
  let lc = ToolLifecycle::requested(req)
  assert_eq(lc.request().tool_name, "echo")
  assert_eq(lc.request().input, "hi")
  assert_eq(lc.request().call_id, "c1")
}

///|
test "tool registry: create and list" {
  let reg = ToolRegistry::create()
  assert_eq(reg.list_tools().length(), 0)
}

///|
test "tool registry: register and lookup" {
  let reg = ToolRegistry::create()
  let meta : ToolMetadata = {
    name: "echo",
    description: "echo tool",
    permissions: [],
    version: "1.0.0",
  }
  reg.register("echo", meta, fn(input) { ExecResult::ok(input) })
  assert_true(reg.has_tool("echo"))
  assert_true(!reg.has_tool("missing"))

  let found = reg.lookup("echo").unwrap()
  assert_eq(found.name, "echo")
  assert_eq(found.version, "1.0.0")
}

///|
test "tool registry: execute tool" {
  let reg = ToolRegistry::create()
  let meta : ToolMetadata = {
    name: "echo",
    description: "echo tool",
    permissions: [],
    version: "1.0.0",
  }
  reg.register("echo", meta, fn(input) { ExecResult::ok(input) })

  let result = reg.execute("echo", "hello").unwrap()
  assert_eq(result.output, "hello")
  assert_true(result.success)
}

///|
test "tool registry: execute missing tool" {
  let reg = ToolRegistry::create()
  assert_true(reg.execute("missing", "input") is Err(_))
}

///|
test "tool registry: register replaces existing" {
  let reg = ToolRegistry::create()
  let meta1 : ToolMetadata = {
    name: "echo",
    description: "v1",
    permissions: [],
    version: "1.0.0",
  }
  let meta2 : ToolMetadata = {
    name: "echo",
    description: "v2",
    permissions: [],
    version: "2.0.0",
  }
  reg.register("echo", meta1, fn(input) { ExecResult::ok("v1:" + input) })
  reg.register("echo", meta2, fn(input) { ExecResult::ok("v2:" + input) })

  assert_eq(reg.list_tools().length(), 1)
  let found = reg.lookup("echo").unwrap()
  assert_eq(found.version, "2.0.0")

  let result = reg.execute("echo", "test").unwrap()
  assert_eq(result.output, "v2:test")
}

///|
test "tool registry: register_tool with Tool trait" {
  let reg = ToolRegistry::create()
  reg.register_tool(EchoTool::{ name: "echo" })
  assert_true(reg.has_tool("echo"))

  let result = reg.execute("echo", "hello").unwrap()
  assert_eq(result.output, "hello")
  assert_true(result.success)
}

///|
test "tool registry: multiple tools" {
  let reg = ToolRegistry::create()
  reg.register_tool(EchoTool::{ name: "echo" })
  reg.register_tool(FailTool::{ name: "fail", error_message: "always fails" })

  assert_eq(reg.list_tools().length(), 2)

  let echo_result = reg.execute("echo", "hi").unwrap()
  assert_eq(echo_result.output, "hi")

  let fail_result = reg.execute("fail", "hi").unwrap()
  assert_true(!fail_result.success)
  assert_eq(fail_result.error, "always fails")
}

///|
test "full workflow: lifecycle with registry execution" {
  let reg = ToolRegistry::create()
  reg.register_tool(EchoTool::{ name: "echo" })

  let req = { tool_name: "echo", input: "hello", call_id: "c1" }
  let lc = ToolLifecycle::requested(req)

  let approved = lc.approve([]).unwrap()
  let executing = approved.start_executing().unwrap()

  let result = reg.execute("echo", "hello").unwrap()
  let completed = executing.complete(result).unwrap()

  assert_true(completed.is_completed())
  assert_true(completed.is_terminal())

  let final_req = completed.request()
  assert_eq(final_req.tool_name, "echo")
}

///|
test "permission-gated approval workflow" {
  let reg = ToolRegistry::create()
  reg.register_tool(FileReaderTool::{  })

  let meta = reg.lookup("read_file").unwrap()
  let req = { tool_name: "read_file", input: "/tmp/test", call_id: "c1" }
  let lc = ToolLifecycle::requested(req)

  let session_perms : Array[Permission] = [FileRead("/tmp"), FileWrite("/tmp")]
  assert_true(permissions_satisfied(meta.permissions, session_perms))

  let approved = lc.approve(session_perms).unwrap()
  assert_true(approved.is_approved())
}
