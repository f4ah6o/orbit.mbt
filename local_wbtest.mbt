///|
test "MemoryStorage read/write/list" {
  let store = MemoryStorage::create()
  let ids = store.list()
  assert_eq(ids.length(), 0)

  store.write("s1", "data1")
  store.write("s2", "data2")

  let ids2 = store.list()
  assert_eq(ids2.length(), 2)

  match store.read("s1") {
    Some(v) => assert_eq(v, "data1")
    None => assert_true(false)
  }

  match store.read("s2") {
    Some(v) => assert_eq(v, "data2")
    None => assert_true(false)
  }

  match store.read("missing") {
    Some(_) => assert_true(false)
    None => ()
  }
}

///|
test "MemoryStorage write overwrites" {
  let store = MemoryStorage::create()
  store.write("s1", "v1")
  store.write("s1", "v2")

  let ids = store.list()
  assert_eq(ids.length(), 1)

  match store.read("s1") {
    Some(v) => assert_eq(v, "v2")
    None => assert_true(false)
  }
}

///|
test "MemoryStorage delete" {
  let store = MemoryStorage::create()
  store.write("s1", "data1")
  store.write("s2", "data2")
  store.delete("s1")

  let ids = store.list()
  assert_eq(ids.length(), 1)
  assert_eq(ids[0], "s2")

  match store.read("s1") {
    Some(_) => assert_true(false)
    None => ()
  }
}

///|
test "event_to_json round-trip — UserMessage" {
  let ev = UserMessage("hello")
  let json = event_to_json(ev)
  let parsed = event_from_json(json)
  match parsed {
    Some(UserMessage("hello")) => ()
    _ => assert_true(false)
  }
}

///|
test "event_to_json round-trip — AssistantMessage" {
  let ev = AssistantMessage("hi there")
  let json = event_to_json(ev)
  let parsed = event_from_json(json)
  match parsed {
    Some(AssistantMessage("hi there")) => ()
    _ => assert_true(false)
  }
}

///|
test "event_to_json round-trip — ToolCall" {
  let req = { tool_name: "echo", input: "{\"x\":1}", call_id: "c1" }
  let ev = ToolCall(req)
  let json = event_to_json(ev)
  let parsed = event_from_json(json)
  match parsed {
    Some(ToolCall(r)) => {
      assert_eq(r.tool_name, "echo")
      assert_eq(r.call_id, "c1")
    }
    _ => assert_true(false)
  }
}

///|
test "event_to_json round-trip — ToolResult success" {
  let res = { call_id: "c1", output: "ok", success: true }
  let ev = ToolResult(res)
  let json = event_to_json(ev)
  let parsed = event_from_json(json)
  match parsed {
    Some(ToolResult(r)) => {
      assert_eq(r.call_id, "c1")
      assert_eq(r.output, "ok")
      assert_eq(r.success, true)
    }
    _ => assert_true(false)
  }
}

///|
test "event_to_json round-trip — ToolResult failure" {
  let res = { call_id: "c2", output: "", success: false }
  let ev = ToolResult(res)
  let json = event_to_json(ev)
  let parsed = event_from_json(json)
  match parsed {
    Some(ToolResult(r)) => {
      assert_eq(r.call_id, "c2")
      assert_eq(r.success, false)
    }
    _ => assert_true(false)
  }
}

///|
test "event_to_json round-trip — Reason" {
  let ev = Reason("something went wrong")
  let json = event_to_json(ev)
  let parsed = event_from_json(json)
  match parsed {
    Some(Reason("something went wrong")) => ()
    _ => assert_true(false)
  }
}

///|
test "event_to_json round-trip — SessionStarted" {
  let ev = SessionStarted("s1")
  let json = event_to_json(ev)
  let parsed = event_from_json(json)
  match parsed {
    Some(SessionStarted("s1")) => ()
    _ => assert_true(false)
  }
}

///|
test "event_to_json round-trip — SessionEnded" {
  let ev = SessionEnded("s1")
  let json = event_to_json(ev)
  let parsed = event_from_json(json)
  match parsed {
    Some(SessionEnded("s1")) => ()
    _ => assert_true(false)
  }
}

///|
test "event_to_json round-trip — StreamChunk" {
  let ev = StreamChunk("Hello ")
  let json = event_to_json(ev)
  let parsed = event_from_json(json)
  match parsed {
    Some(StreamChunk("Hello ")) => ()
    _ => assert_true(false)
  }
}

///|
test "event_to_json round-trip — Transition" {
  let ev = Transition("s1", "s2")
  let json = event_to_json(ev)
  let parsed = event_from_json(json)
  match parsed {
    Some(Transition("s1", "s2")) => ()
    _ => assert_true(false)
  }
}

///|
test "event_to_json handles special characters" {
  let ev = UserMessage("he\"llo\nworld")
  let json = event_to_json(ev)
  let parsed = event_from_json(json)
  match parsed {
    Some(UserMessage("he\"llo\nworld")) => ()
    _ => assert_true(false)
  }
}

///|
test "event_to_json handles backslash" {
  let ev = AssistantMessage("a\\b")
  let json = event_to_json(ev)
  let parsed = event_from_json(json)
  match parsed {
    Some(AssistantMessage("a\\b")) => ()
    _ => assert_true(false)
  }
}

///|
test "event_from_json invalid type returns None" {
  let result = event_from_json("{\"type\":\"Unknown\",\"content\":\"x\"}")
  match result {
    Some(_) => assert_true(false)
    None => ()
  }
}

///|
test "session_to_json idle session" {
  let s = Session::create("s1")
  let json = session_to_json(s)
  let expected = "{\"id\":\"s1\",\"events\":[]}"
  assert_eq(json, expected)
}

///|
test "session_to_json running session with messages matches fixture" {
  let s = Session::create("s1")
    .start()
    .unwrap()
    .send_user_message("hello")
    .unwrap()
    .receive_assistant_message("hi")
    .unwrap()
  let json = session_to_json(s)
  let expected = "{\"id\":\"s1\",\"events\":[{\"type\":\"SessionStarted\",\"session_id\":\"s1\"},{\"type\":\"UserMessage\",\"content\":\"hello\"},{\"type\":\"AssistantMessage\",\"content\":\"hi\"}]}"
  assert_eq(json, expected)
}

///|
test "session_to_json failed session matches fixture" {
  let s = Session::create("s1").start().unwrap().fail("timeout")
  let json = session_to_json(s)
  let expected = "{\"id\":\"s1\",\"events\":[{\"type\":\"SessionStarted\",\"session_id\":\"s1\"},{\"type\":\"Reason\",\"message\":\"timeout\"}]}"
  assert_eq(json, expected)
}

///|
test "session_to_json waiting_tool session matches fixture" {
  let req = { tool_name: "echo", input: "{}", call_id: "c1" }
  let s = Session::create("s1").start().unwrap().request_tool(req).unwrap()
  let json = session_to_json(s)
  let expected = "{\"id\":\"s1\",\"events\":[{\"type\":\"SessionStarted\",\"session_id\":\"s1\"},{\"type\":\"ToolCall\",\"tool_name\":\"echo\",\"input\":\"{}\",\"call_id\":\"c1\"}]}"
  assert_eq(json, expected)
}

///|
test "session_from_json idle session" {
  let json = "{\"id\":\"s1\",\"events\":[]}"
  let s = session_from_json(json)
  match s {
    Some(session) => {
      assert_eq(session.id, "s1")
      assert_eq(session.is_idle(), true)
      assert_eq(session.event_count(), 0)
    }
    None => assert_true(false)
  }
}

///|
test "session_from_json running session with messages" {
  let json = "{\"id\":\"s1\",\"events\":[{\"type\":\"SessionStarted\",\"session_id\":\"s1\"},{\"type\":\"UserMessage\",\"content\":\"hello\"},{\"type\":\"AssistantMessage\",\"content\":\"hi\"}]}"
  let s = session_from_json(json)
  match s {
    Some(session) => {
      assert_eq(session.id, "s1")
      assert_eq(session.is_running(), true)
      assert_eq(session.event_count(), 3)
    }
    None => assert_true(false)
  }
}

///|
test "session_from_json failed session" {
  let json = "{\"id\":\"s1\",\"events\":[{\"type\":\"SessionStarted\",\"session_id\":\"s1\"},{\"type\":\"Reason\",\"message\":\"timeout\"}]}"
  let s = session_from_json(json)
  match s {
    Some(session) => {
      assert_eq(session.id, "s1")
      assert_eq(session.is_failed(), true)
      assert_eq(session.event_count(), 2)
    }
    None => assert_true(false)
  }
}

///|
test "session_from_json waiting_tool session" {
  let json = "{\"id\":\"s1\",\"events\":[{\"type\":\"SessionStarted\",\"session_id\":\"s1\"},{\"type\":\"ToolCall\",\"tool_name\":\"echo\",\"input\":\"{}\",\"call_id\":\"c1\"}]}"
  let s = session_from_json(json)
  match s {
    Some(session) => {
      assert_eq(session.id, "s1")
      assert_eq(session.is_waiting_tool(), true)
      assert_eq(session.event_count(), 2)
    }
    None => assert_true(false)
  }
}

///|
test "session round-trip preserves state and events" {
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

  let json = session_to_json(original)
  match session_from_json(json) {
    Some(restored) => {
      assert_eq(restored.id, original.id)
      assert_true(restored.state == original.state)
      assert_eq(restored.event_count(), original.event_count())
    }
    None => assert_true(false)
  }
}

///|
test "session_from_json invalid json returns None" {
  let result = session_from_json("not json at all")
  match result {
    Some(_) => assert_true(false)
    None => ()
  }
}

///|
test "session_from_json missing id field returns None" {
  let result = session_from_json("{\"events\":[]}")
  match result {
    Some(_) => assert_true(false)
    None => ()
  }
}

///|
test "SessionCache cache and load" {
  let store = MemoryStorage::create()
  let cache = SessionCache::create(store)

  let s = Session::create("s1").start().unwrap()
  cache.cache(s)

  assert_eq(cache.contains("s1"), true)
  assert_eq(cache.contains("missing"), false)

  match cache.load("s1") {
    Some(restored) => {
      assert_eq(restored.id, "s1")
      assert_eq(restored.is_running(), true)
    }
    None => assert_true(false)
  }

  match cache.load("missing") {
    Some(_) => assert_true(false)
    None => ()
  }
}

///|
test "SessionCache list_ids" {
  let store = MemoryStorage::create()
  let cache = SessionCache::create(store)

  let s1 = Session::create("s1")
  let s2 = Session::create("s2")
  cache.cache(s1)
  cache.cache(s2)

  let ids = cache.list_ids()
  assert_eq(ids.length(), 2)
}

///|
test "SessionCache remove" {
  let store = MemoryStorage::create()
  let cache = SessionCache::create(store)

  let s = Session::create("s1")
  cache.cache(s)
  assert_eq(cache.contains("s1"), true)

  cache.remove("s1")
  assert_eq(cache.contains("s1"), false)
}

///|
test "SessionCache overwrites existing" {
  let store = MemoryStorage::create()
  let cache = SessionCache::create(store)

  let s1 = Session::create("s1")
  let s2 = Session::create("s1").start().unwrap()
  cache.cache(s1)
  cache.cache(s2)

  match cache.load("s1") {
    Some(restored) => {
      assert_eq(restored.is_running(), true)
      assert_eq(restored.event_count(), 1)
    }
    None => assert_true(false)
  }
}

///|
test "SessionIndex add, list, contains, count" {
  let store = MemoryStorage::create()
  let index = SessionIndex::create(store)

  assert_eq(index.count(), 0)
  assert_eq(index.contains("s1"), false)

  index.add("s1")
  assert_eq(index.count(), 1)
  assert_eq(index.contains("s1"), true)

  index.add("s2")
  assert_eq(index.count(), 2)

  let ids = index.list()
  assert_eq(ids.length(), 2)
}

///|
test "SessionIndex remove" {
  let store = MemoryStorage::create()
  let index = SessionIndex::create(store)

  index.add("s1")
  index.add("s2")
  assert_eq(index.count(), 2)

  index.remove("s1")
  assert_eq(index.count(), 1)
  assert_eq(index.contains("s1"), false)
  assert_eq(index.contains("s2"), true)
}

///|
test "SessionIndex remove non-existent is no-op" {
  let store = MemoryStorage::create()
  let index = SessionIndex::create(store)
  index.remove("missing")
  assert_eq(index.count(), 0)
}

///|
test "cache then load preserves full session with tool cycle" {
  let store = MemoryStorage::create()
  let cache = SessionCache::create(store)

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

  cache.cache(original)

  match cache.load("s1") {
    Some(restored) => {
      assert_eq(restored.id, "s1")
      assert_eq(restored.is_running(), true)
      assert_eq(restored.event_count(), 5)
      assert_true(restored.state == original.state)
    }
    None => assert_true(false)
  }
}
