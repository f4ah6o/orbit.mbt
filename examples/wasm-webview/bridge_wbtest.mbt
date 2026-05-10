///|
test "wasm webview exports initial App Server artifacts" {
  reset_demo()
  let snapshot = get_snapshot_json()
  assert_true(
    snapshot.contains("\"schema_version\":\"orbit.app_server.session.v1\""),
  )
  assert_true(snapshot.contains("\"session_id\":\"demo\""))
  assert_true(snapshot.contains("\"state\":\"idle\""))
  assert_true(snapshot.contains("\"resource\":{"))
  let catalog = get_session_tool_catalog_json()
  assert_true(
    catalog.contains("\"schema_version\":\"orbit.app_server.session_tools.v1\""),
  )
  assert_true(catalog.contains("\"name\":\"get_session_snapshot\""))
}

///|
test "wasm webview exports pending tool snapshot plan and replay" {
  reset_demo()
  dispatch_event("start", "")
  dispatch_event("user_message", "hello from test")
  dispatch_event("request_tool", "")
  let html = get_resource_html()
  assert_true(html.contains("waiting_tool"))
  let resource = get_resource_json()
  assert_true(resource.contains("\"state\":\"waiting_tool\""))
  let snapshot = get_snapshot_json()
  assert_true(
    snapshot.contains("\"pending_tool\":{\"lifecycle_state\":\"requested\""),
  )
  assert_true(snapshot.contains("\"tool_name\":\"demo.read\""))
  assert_true(
    snapshot.contains("\"kind\":\"file_read\",\"value\":\"/demo/session.txt\""),
  )
  let plan = get_execute_tool_plan_json()
  assert_true(plan.contains("\"tool_name\":\"execute_tool_request\""))
  assert_true(plan.contains("\"approval_required\":true"))
  let replay = get_replay_export_json()
  assert_true(
    replay.contains("\"artifact_type\":\"orbit.app_server.replay_export\""),
  )
  assert_true(
    replay.contains("\"type\":\"UserMessage\",\"content\":\"hello from test\""),
  )
}
