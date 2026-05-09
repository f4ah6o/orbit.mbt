///|
test "VFS::read on missing file returns Err" {
  let vfs = VFS::new()
  let result = vfs.read("missing.txt")
  assert_true(result is Err(_))
}

///|
test "VFS::write creates file and read returns content" {
  let vfs = VFS::new()
  let vfs = vfs.write("hello.txt", "world")
  let result = vfs.read("hello.txt")
  match result {
    Ok(content) => assert_eq(content, "world")
    Err(_) => assert_true(false)
  }
}

///|
test "VFS::write overwrites existing file" {
  let vfs = VFS::new()
  let vfs = vfs.write("a.txt", "first")
  let vfs = vfs.write("a.txt", "second")
  let result = vfs.read("a.txt")
  match result {
    Ok(content) => assert_eq(content, "second")
    Err(_) => assert_true(false)
  }
}

///|
test "VFS::list returns files under directory" {
  let vfs = VFS::new()
  let vfs = vfs.write("src/main.mbt", "fn main {}")
  let vfs = vfs.write("src/lib.mbt", "fn lib {}")
  let vfs = vfs.write("README.md", "# readme")
  let entries = vfs.list("src")
  assert_eq(entries.length(), 2)
}

///|
test "ReadFileTool execute returns file content" {
  let vfs : Ref[VFS] = { val: VFS::new().write("README.mbt.md", "# orbit") }
  let tool = ReadFileTool::{ vfs, }
  let result = tool.execute("README.mbt.md")
  assert_eq(result.success, true)
  assert_eq(result.output, "# orbit")
}

///|
test "ReadFileTool execute on missing file returns error" {
  let vfs : Ref[VFS] = { val: VFS::new() }
  let tool = ReadFileTool::{ vfs, }
  let result = tool.execute("missing.txt")
  assert_eq(result.success, false)
  assert_true(result.error.length() > 0)
}

///|
test "WriteFileTool creates file in VFS" {
  let vfs : Ref[VFS] = { val: VFS::new() }
  let tool = WriteFileTool::{ vfs, }
  let result = tool.execute("new.txt:hello world")
  assert_eq(result.success, true)
  let read_result = vfs.val.read("new.txt")
  match read_result {
    Ok(content) => assert_eq(content, "hello world")
    Err(_) => assert_true(false)
  }
}

///|
test "WriteFileTool rejects invalid input format" {
  let vfs : Ref[VFS] = { val: VFS::new() }
  let tool = WriteFileTool::{ vfs, }
  let result = tool.execute("no-colon-here")
  assert_eq(result.success, false)
}

///|
test "ListDirTool lists files in VFS directory" {
  let vfs : Ref[VFS] = { val: VFS::new().write("src/main.mbt", "fn main {}") }
  let tool = ListDirTool::{ vfs, }
  let result = tool.execute("src")
  assert_eq(result.success, true)
  assert_eq(result.output, "src/main.mbt")
}

///|
test "ListDirTool lists empty directory as empty output" {
  let vfs : Ref[VFS] = { val: VFS::new().write("src/main.mbt", "fn main {}") }
  let tool = ListDirTool::{ vfs, }
  let result = tool.execute("missing")
  assert_eq(result.success, true)
  assert_eq(result.output, "")
}

///|
test "Allow gate completes tool call, session returns to Running" {
  let vfs : Ref[VFS] = { val: VFS::new().write("test.txt", "hello") }
  let reg = @orbit.ToolRegistry::create()
  let tool = ReadFileTool::{ vfs, }
  let meta = tool.metadata()
  reg.register(meta.name, meta, fn(input) { tool.execute(input) })

  let session = @orbit.Session::create("test-allow")
  let session = session.start().unwrap()
  let req : @orbit.ToolRequest = {
    tool_name: "read_file",
    input: "test.txt",
    call_id: "c1",
  }
  let session = session.request_tool(req).unwrap()

  // Verify in WaitingTool state
  assert_true(session.is_waiting_tool())

  let session = gate_decide(session, reg, Allow)

  // Verify returned to Running state
  assert_true(session.is_running())
}

///|
test "Deny gate puts session in Failed state" {
  let vfs : Ref[VFS] = { val: VFS::new().write("test.txt", "hello") }
  let reg = @orbit.ToolRegistry::create()
  let tool = ReadFileTool::{ vfs, }
  let meta = tool.metadata()
  reg.register(meta.name, meta, fn(input) { tool.execute(input) })

  let session = @orbit.Session::create("test-deny")
  let session = session.start().unwrap()
  let req : @orbit.ToolRequest = {
    tool_name: "read_file",
    input: "test.txt",
    call_id: "c1",
  }
  let session = session.request_tool(req).unwrap()

  let session = gate_decide(session, reg, Deny)

  assert_true(session.is_failed())
}

///|
test "Deny gate reason contains tool name" {
  let vfs : Ref[VFS] = { val: VFS::new().write("test.txt", "hello") }
  let reg = @orbit.ToolRegistry::create()
  let tool = ReadFileTool::{ vfs, }
  let meta = tool.metadata()
  reg.register(meta.name, meta, fn(input) { tool.execute(input) })

  let session = @orbit.Session::create("test-deny-reason")
  let session = session.start().unwrap()
  let req : @orbit.ToolRequest = {
    tool_name: "read_file",
    input: "test.txt",
    call_id: "c1",
  }
  let session = session.request_tool(req).unwrap()

  let session = gate_decide(session, reg, Deny)

  // The fail event log should contain the deny reason
  let mut found_reason = false
  for event in session.event_log {
    match event {
      @orbit.Reason(msg) =>
        if msg.contains("denied by user: read_file") {
          found_reason = true
        }
      _ => ()
    }
  }
  assert_true(found_reason)
}

///|
test "available_actions in WaitingTool state includes respond_tool and end" {
  let session = @orbit.Session::create("test-actions")
  let session = session.start().unwrap()
  let req : @orbit.ToolRequest = {
    tool_name: "read_file",
    input: "test.txt",
    call_id: "c1",
  }
  let session = session.request_tool(req).unwrap()

  let actions = @orbit.available_actions(session)
  let mut has_respond = false
  let mut has_end = false
  for action in actions {
    if action.rel == "respond_tool" {
      has_respond = true
    }
    if action.rel == "end" {
      has_end = true
    }
  }
  assert_true(has_respond)
  assert_true(has_end)
}
