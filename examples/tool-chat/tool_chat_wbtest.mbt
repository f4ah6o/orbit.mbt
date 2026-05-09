///|
test "EchoTool echoes input correctly" {
  let result = echo_execute("hello")
  assert_eq(result.output, "hello")
  assert_eq(result.success, true)
}

///|
test "EchoTool metadata" {
  let meta = echo_metadata()
  assert_eq(meta.name, "echo")
  assert_eq(meta.description, "Echoes the input back as output")
}

///|
test "ClockTool returns fixed timestamp" {
  let result = clock_execute("")
  assert_eq(result.output, "2026-05-09T12:00:00Z")
  assert_eq(result.success, true)
}

///|
test "ClockTool ignores input" {
  let result = clock_execute("anything")
  assert_eq(result.output, "2026-05-09T12:00:00Z")
}

///|
test "AddTool 3+4 returns 7" {
  let result = add_execute("3,4")
  assert_eq(result.output, "7")
  assert_eq(result.success, true)
}

///|
test "AddTool with bad input returns failure" {
  let result = add_execute("bad")
  assert_true(!result.success)
  assert_true(result.error.length() > 0)
}

///|
test "AddTool with non-numeric input returns failure" {
  let result = add_execute("a,b")
  assert_true(!result.success)
}

///|
test "step on non-WaitingTool session returns session unchanged" {
  let reg = @orbit.ToolRegistry::create()
  register_tools(reg)

  let session = @orbit.Session::create("test")
    .start()
    .unwrap()
  let expected_count = session.event_count()
  let session = step(session, reg)
  assert_eq(session.event_count(), expected_count)
  assert_true(session.is_running())
}

///|
test "step on WaitingTool session dispatches tool" {
  let reg = @orbit.ToolRegistry::create()
  register_tools(reg)

  let session = @orbit.Session::create("test")
    .start()
    .unwrap()
  let req : @orbit.ToolRequest = {
    tool_name: "echo",
    input: "hello",
    call_id: "c1",
  }
  let session = session.request_tool(req).unwrap()

  assert_true(session.is_waiting_tool())

  let session = step(session, reg)
  assert_true(session.is_running())
  assert_eq(session.event_count(), 3)
}

///|
test "add scenario via step then check running state" {
  let reg = @orbit.ToolRegistry::create()
  register_tools(reg)

  let session = @orbit.Session::create("test-add")
    .start()
    .unwrap()
  let req : @orbit.ToolRequest = {
    tool_name: "add",
    input: "3,4",
    call_id: "c1",
  }
  let session = session.request_tool(req).unwrap()
  let session = step(session, reg)

  assert_true(session.is_running())
}

///|
test "full echo event log replays deterministically" {
  let events : Array[@orbit.AgentEvent] = [
    @orbit.SessionStarted("replay-echo"),
    @orbit.UserMessage("hello"),
    @orbit.ToolCall({
      tool_name: "echo",
      input: "hello",
      call_id: "c1",
    }),
    @orbit.ToolResult({
      call_id: "c1",
      output: "hello",
      success: true,
    }),
    @orbit.AssistantMessage("Echo: hello"),
    @orbit.SessionEnded("replay-echo"),
  ]
  let replayed = @orbit.Session::replay("replay-echo", events)
  assert_eq(replayed.event_count(), events.length())
  assert_true(replayed.is_idle())
}

///|
test "tool registry has all demo tools" {
  let reg = @orbit.ToolRegistry::create()
  register_tools(reg)
  assert_true(reg.has_tool("echo"))
  assert_true(reg.has_tool("clock"))
  assert_true(reg.has_tool("add"))
}
