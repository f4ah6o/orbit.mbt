///|
test "action struct equality" {
  let a1 = { rel: "start", method: "POST", href: "/session/s1/actions/start" }
  let a2 = { rel: "start", method: "POST", href: "/session/s1/actions/start" }
  let a3 = { rel: "end", method: "POST", href: "/session/s1/actions/end" }
  assert_true(a1 == a2)
  assert_true(a1 != a3)
}

///|
test "action to_json" {
  let a = { rel: "start", method: "POST", href: "/session/s1/actions/start" }
  assert_eq(
    a.to_json(),
    "{\"rel\":\"start\",\"method\":\"POST\",\"href\":\"/session/s1/actions/start\"}",
  )
}

///|
test "message entry to_json" {
  let m = { role: "user", content: "hello" }
  assert_eq(m.to_json(), "{\"role\":\"user\",\"content\":\"hello\"}")
}

///|
test "link to_json" {
  let l = { rel: "self", href: "/session/s1" }
  assert_eq(l.to_json(), "{\"rel\":\"self\",\"href\":\"/session/s1\"}")
}

///|
test "available_actions for idle session" {
  let s = Session::create("s1")
  let actions = available_actions(s)
  assert_eq(actions.length(), 1)
  assert_eq(actions[0].rel, "start")
  assert_eq(actions[0].method, "POST")
}

///|
test "available_actions for running session" {
  let s = Session::create("s1").start().unwrap()
  let actions = available_actions(s)
  assert_eq(actions.length(), 3)
}

///|
test "available_actions for waiting_tool session" {
  let req = { tool_name: "echo", input: "{}", call_id: "c1" }
  let s = Session::create("s1").start().unwrap().request_tool(req).unwrap()
  let actions = available_actions(s)
  assert_eq(actions.length(), 2)
}

///|
test "available_actions for failed session" {
  let s = Session::create("s1").start().unwrap().fail("oops")
  let actions = available_actions(s)
  assert_eq(actions.length(), 0)
}

///|
test "reasons_projection collects reason events" {
  let s = Session::create("s1").start().unwrap().fail("something went wrong")
  let reasons = reasons_projection(s)
  assert_eq(reasons.length(), 1)
  assert_eq(reasons[0], "something went wrong")
}

///|
test "reasons_projection empty when no failures" {
  let s = Session::create("s1").start().unwrap()
  let reasons = reasons_projection(s)
  assert_eq(reasons.length(), 0)
}

///|
test "project idle session" {
  let s = Session::create("s1")
  let r = project(s)
  assert_eq(r.state, "idle")
  assert_eq(r.messages.length(), 0)
  assert_eq(r.available_actions.length(), 1)
  assert_eq(r.reasons.length(), 0)
  assert_eq(r.links.length(), 1)
  assert_eq(r.links[0].rel, "self")
}

///|
test "project running session with messages" {
  let s = Session::create("s1")
    .start()
    .unwrap()
    .send_user_message("hello")
    .unwrap()
    .receive_assistant_message("hi")
    .unwrap()
  let r = project(s)
  assert_eq(r.state, "running")
  assert_eq(r.messages.length(), 2)
  assert_eq(r.messages[0].role, "user")
  assert_eq(r.messages[0].content, "hello")
  assert_eq(r.messages[1].role, "assistant")
  assert_eq(r.messages[1].content, "hi")
}

///|
test "project failed session with reasons" {
  let s = Session::create("s1").start().unwrap().fail("timeout")
  let r = project(s)
  assert_eq(r.state, "failed")
  assert_eq(r.reasons.length(), 1)
  assert_eq(r.reasons[0], "timeout")
  assert_eq(r.available_actions.length(), 0)
}

///|
test "to_json_string idle session" {
  let s = Session::create("s1")
  let json = project(s).to_json_string()
  let expected = "{\"state\":\"idle\",\"messages\":[],\"available_actions\":[{\"rel\":\"start\",\"method\":\"POST\",\"href\":\"/session/s1/actions/start\"}],\"reasons\":[],\"links\":[{\"rel\":\"self\",\"href\":\"/session/s1\"}]}"
  assert_eq(json, expected)
}

///|
test "to_json_string running session with messages" {
  let s = Session::create("s1")
    .start()
    .unwrap()
    .send_user_message("hello")
    .unwrap()
    .receive_assistant_message("hi")
    .unwrap()
  let json = project(s).to_json_string()
  let expected = "{\"state\":\"running\",\"messages\":[{\"role\":\"user\",\"content\":\"hello\"},{\"role\":\"assistant\",\"content\":\"hi\"}],\"available_actions\":[{\"rel\":\"send_message\",\"method\":\"POST\",\"href\":\"/session/s1/actions/message\"},{\"rel\":\"end\",\"method\":\"POST\",\"href\":\"/session/s1/actions/end\"},{\"rel\":\"request_tool\",\"method\":\"POST\",\"href\":\"/session/s1/actions/tool\"}],\"reasons\":[],\"links\":[{\"rel\":\"self\",\"href\":\"/session/s1\"}]}"
  assert_eq(json, expected)
}

///|
test "to_json_string waiting_tool session" {
  let req = { tool_name: "echo", input: "{}", call_id: "c1" }
  let s = Session::create("s1").start().unwrap().request_tool(req).unwrap()
  let json = project(s).to_json_string()
  let expected = "{\"state\":\"waiting_tool\",\"messages\":[],\"available_actions\":[{\"rel\":\"respond_tool\",\"method\":\"POST\",\"href\":\"/session/s1/actions/tool\"},{\"rel\":\"end\",\"method\":\"POST\",\"href\":\"/session/s1/actions/end\"}],\"reasons\":[],\"links\":[{\"rel\":\"self\",\"href\":\"/session/s1\"}]}"
  assert_eq(json, expected)
}

///|
test "to_json_string failed session" {
  let s = Session::create("s1").start().unwrap().fail("timeout")
  let json = project(s).to_json_string()
  let expected = "{\"state\":\"failed\",\"messages\":[],\"available_actions\":[],\"reasons\":[\"timeout\"],\"links\":[{\"rel\":\"self\",\"href\":\"/session/s1\"}]}"
  assert_eq(json, expected)
}

///|
test "json output is deterministic across replays" {
  let req = { tool_name: "echo", input: "{}", call_id: "c1" }
  let res = { call_id: "c1", output: "ok", success: true }
  let original = Session::create("s1")
    .start()
    .unwrap()
    .send_user_message("hello")
    .unwrap()
    .request_tool(req)
    .unwrap()
    .respond_tool(res)
    .unwrap()
    .receive_assistant_message("done")
    .unwrap()
  let json1 = project(original).to_json_string()

  let replayed = Session::replay("s1", original.event_log)
  let json2 = project(replayed).to_json_string()

  assert_eq(json1, json2)
}

///|
test "escape_json handles special characters" {
  assert_eq(escape_json("hello"), "hello")
  assert_eq(escape_json("he\"llo"), "he\\\"llo")
  assert_eq(escape_json("he\\llo"), "he\\\\llo")
  assert_eq(escape_json("he\nllo"), "he\\nllo")
  assert_eq(escape_json("he\rllo"), "he\\rllo")
  assert_eq(escape_json("he\tllo"), "he\\tllo")
}

///|
test "resource debug equality" {
  let r1 = project(Session::create("s1"))
  let r2 = project(Session::create("s1"))
  assert_true(r1 == r2)
}

///|
test "project waiting_tool session" {
  let req = { tool_name: "read_file", input: "{}", call_id: "c1" }
  let s = Session::create("s1").start().unwrap().request_tool(req).unwrap()
  let r = project(s)
  assert_eq(r.state, "waiting_tool")
  assert_eq(r.available_actions.length(), 2)
}
