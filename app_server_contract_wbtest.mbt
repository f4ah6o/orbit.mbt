///|
fn app_server_test_registry() -> ToolRegistry {
  let registry = ToolRegistry::create()
  let meta : ToolMetadata = {
    name: "read_file",
    description: "read a file",
    permissions: [FileRead("/workspace")],
    version: "1.0.0",
  }
  registry.register("read_file", meta, fn(input) { ExecResult::ok(input) })
  registry
}

///|
test "app server snapshot json includes stable top-level contract fields" {
  let registry = app_server_test_registry()
  let session = Session::create("s-app")
    .start()
    .unwrap()
    .send_user_message("hello")
    .unwrap()
    .receive_assistant_message("hi")
    .unwrap()
  let json = session.app_server_snapshot_json(registry, [])
  assert_true(
    str_index_of(json, "\"schema_version\":\"orbit.app_server.session.v1\"")
    is Some(_),
  )
  assert_true(str_index_of(json, "\"session_id\":\"s-app\"") is Some(_))
  assert_true(str_index_of(json, "\"state\":\"running\"") is Some(_))
  assert_true(str_index_of(json, "\"event_log\":[") is Some(_))
  assert_true(
    str_index_of(
      json, "\"messages\":[{\"role\":\"user\",\"content\":\"hello\"},{\"role\":\"assistant\",\"content\":\"hi\"}]",
    )
    is Some(_),
  )
  assert_true(str_index_of(json, "\"pending_tool\":null") is Some(_))
  assert_true(str_index_of(json, "\"resource\":{") is Some(_))
  assert_true(
    str_index_of(json, "\"last_action\":{\"kind\":\"assistant_message\"")
    is Some(_),
  )
}

///|
test "app server snapshot captures waiting tool request and approval metadata" {
  let registry = app_server_test_registry()
  let req = {
    tool_name: "read_file",
    input: "/workspace/README.md",
    call_id: "call-1",
  }
  let session = Session::create("s-tool")
    .start()
    .unwrap()
    .request_tool(req)
    .unwrap()
  let snapshot = session.app_server_snapshot(registry, [])
  assert_eq(snapshot.state, "waiting_tool")
  match snapshot.pending_tool {
    Some(tool) => {
      assert_eq(tool.lifecycle_state, "requested")
      assert_eq(tool.request.tool_name, "read_file")
      assert_true(tool.registered)
    }
    None => assert_true(false)
  }
  assert_true(snapshot.approval.approval_required)
  assert_eq(snapshot.approval.required_permissions.length(), 1)
  assert_eq(snapshot.approval.missing_permissions.length(), 1)
  assert_eq(snapshot.diagnostics.length(), 1)

  let json = snapshot.to_json_string()
  assert_true(
    str_index_of(json, "\"pending_tool\":{\"lifecycle_state\":\"requested\"")
    is Some(_),
  )
  assert_true(str_index_of(json, "\"approval_required\":true") is Some(_))
  assert_true(
    str_index_of(
      json, "\"missing_permissions\":[{\"kind\":\"file_read\",\"value\":\"/workspace\"}]",
    )
    is Some(_),
  )
}

///|
test "app server snapshot records granted permission boundary" {
  let registry = app_server_test_registry()
  let req = {
    tool_name: "read_file",
    input: "/workspace/README.md",
    call_id: "call-2",
  }
  let session = Session::create("s-approved")
    .start()
    .unwrap()
    .request_tool(req)
    .unwrap()
  let snapshot = session.app_server_snapshot(registry, [FileRead("/workspace")])
  assert_true(!snapshot.approval.approval_required)
  assert_eq(snapshot.approval.required_permissions.length(), 1)
  assert_eq(snapshot.approval.granted_permissions.length(), 1)
  assert_eq(snapshot.approval.missing_permissions.length(), 0)
  assert_eq(
    snapshot.approval.reason,
    "pending tool permissions are already granted",
  )

  let json = snapshot.to_json_string()
  assert_true(str_index_of(json, "\"approval_required\":false") is Some(_))
  assert_true(
    str_index_of(
      json, "\"granted_permissions\":[{\"kind\":\"file_read\",\"value\":\"/workspace\"}]",
    )
    is Some(_),
  )
}

///|
test "app server replay export envelope embeds snapshot and replay events" {
  let registry = app_server_test_registry()
  let session = Session::create("s-export")
    .start()
    .unwrap()
    .send_user_message("export me")
    .unwrap()
  let json = session.app_server_replay_export_json(registry, [])
  assert_true(
    str_index_of(json, "\"artifact_type\":\"orbit.app_server.replay_export\"")
    is Some(_),
  )
  assert_true(
    str_index_of(
      json, "\"snapshot\":{\"schema_version\":\"orbit.app_server.session.v1\"",
    )
    is Some(_),
  )
  assert_true(str_index_of(json, "\"replay\":{\"events\":[") is Some(_))
  assert_true(
    str_index_of(json, "\"type\":\"UserMessage\",\"content\":\"export me\"")
    is Some(_),
  )
}
