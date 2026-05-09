///|
/// FS Agent permissions demo — allow-flow and deny-flow scenarios.
fn main {
  // Pre-populate VFS with a README file.
  let vfs : Ref[VFS] = {
    val: VFS::new().write(
      "README.mbt.md", "# orbit.mbt\n\nTyped agent runtime.",
    ),
  }

  // Register tools.
  let reg = @orbit.ToolRegistry::create()
  let read_tool = ReadFileTool::{ vfs, }
  reg.register(read_tool.metadata().name, read_tool.metadata(), fn(input) {
    read_tool.execute(input)
  })
  let write_tool = WriteFileTool::{ vfs, }
  reg.register(write_tool.metadata().name, write_tool.metadata(), fn(input) {
    write_tool.execute(input)
  })
  let list_tool = ListDirTool::{ vfs, }
  reg.register(list_tool.metadata().name, list_tool.metadata(), fn(input) {
    list_tool.execute(input)
  })

  // ── Allow flow ──────────────────────────────────────────────
  println("=== Allow flow ===")
  let session = @orbit.Session::create("demo-allow")
  let session = session.start().unwrap()
  let req : @orbit.ToolRequest = {
    tool_name: "read_file",
    input: "README.mbt.md",
    call_id: "c1",
  }
  let session = session.request_tool(req).unwrap()

  // Simulate user clicking "Allow"
  let session = gate_decide(session, reg, Allow)

  // Print the tool output from the event log.
  for event in session.event_log {
    match event {
      @orbit.ToolResult(res) => println("Tool output: " + res.output)
      _ => ()
    }
  }
  println(
    if session.is_running() {
      "Allow flow: SUCCESS"
    } else {
      "Allow flow: FAILED"
    },
  )
  let _ = session.end()

  // ── Deny flow ───────────────────────────────────────────────
  println("=== Deny flow ===")
  let session2 = @orbit.Session::create("demo-deny")
  let session2 = session2.start().unwrap()
  let req2 : @orbit.ToolRequest = {
    tool_name: "read_file",
    input: "secret.txt",
    call_id: "c1",
  }
  let session2 = session2.request_tool(req2).unwrap()

  // Simulate user clicking "Deny"
  let session2 = gate_decide(session2, reg, Deny)

  // Verify: session is in Failed state with deny reason.
  for event in session2.event_log {
    match event {
      @orbit.Reason(msg) => println("Deny reason: " + msg)
      _ => ()
    }
  }
  println(
    if session2.is_failed() {
      "Deny flow: SUCCESS"
    } else {
      "Deny flow: FAILED"
    },
  )
}
