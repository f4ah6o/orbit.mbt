// Whitebox tests — run within package scope.

///|
test "initial session is idle" {
  let s = Session::create("s1")
  assert_eq(s.is_idle(), true)
  assert_eq(s.event_count(), 0)
}

///|
test "start: Idle -> Running" {
  let s = Session::create("s1").start().unwrap()
  assert_eq(s.is_running(), true)
  assert_eq(s.event_count(), 1)
}

///|
test "end: Running -> Idle" {
  let s = Session::create("s1").start().unwrap().end().unwrap()
  assert_eq(s.is_idle(), true)
  assert_eq(s.event_count(), 2)
}

///|
test "request_tool: Running -> WaitingTool" {
  let req = { tool_name: "read_file", input: "{}", call_id: "c1" }
  let s = Session::create("s1").start().unwrap().request_tool(req).unwrap()
  assert_eq(s.is_waiting_tool(), true)
  assert_eq(s.event_count(), 2)
}

///|
test "respond_tool: WaitingTool -> Running" {
  let req = { tool_name: "read_file", input: "{}", call_id: "c1" }
  let res = { call_id: "c1", output: "ok", success: true }
  let s = Session::create("s1")
    .start()
    .unwrap()
    .request_tool(req)
    .unwrap()
    .respond_tool(res)
    .unwrap()
  assert_eq(s.is_running(), true)
  assert_eq(s.event_count(), 3)
}

///|
test "fail: any state -> Failed" {
  let s = Session::create("s1").start().unwrap().fail("oops")
  assert_eq(s.is_failed(), true)
}

///|
test "messages do not change state" {
  let s = Session::create("s1")
    .start()
    .unwrap()
    .send_user_message("hello")
    .unwrap()
    .receive_assistant_message("hi")
    .unwrap()
  assert_eq(s.is_running(), true)
  assert_eq(s.event_count(), 3)
}

///|
test "cannot start an already running session" {
  let s = Session::create("s1").start().unwrap()
  assert_true(s.start() is Err(_))
}

///|
test "cannot end an idle session" {
  let s = Session::create("s1")
  assert_true(s.end() is Err(_))
}

///|
test "replay is deterministic" {
  let req = { tool_name: "read_file", input: "{}", call_id: "c1" }
  let res = { call_id: "c1", output: "ok", success: true }
  let original = Session::create("s1")
    .start()
    .unwrap()
    .send_user_message("hello")
    .unwrap()
    .receive_assistant_message("hi")
    .unwrap()
    .request_tool(req)
    .unwrap()
    .respond_tool(res)
    .unwrap()
  let replayed = Session::replay("s1", original.event_log)
  assert_true(original.state == replayed.state)
  assert_eq(original.event_count(), replayed.event_count())
}

///|
test "replay_from appends new events" {
  let base = Session::create("s1").start().unwrap()
  let extended = base.replay_from([UserMessage("hello")])
  assert_eq(extended.is_running(), true)
  assert_eq(extended.event_count(), 2)
}
