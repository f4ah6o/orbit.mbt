///|
fn app_server_tool_boundary_test_registry() -> ToolRegistry {
  let registry = ToolRegistry::create()
  registry.register(
    "write_file",
    {
      name: "write_file",
      description: "write a file",
      permissions: [FileWrite("/workspace/out.txt")],
      version: "1.0.0",
    },
    fn(input) { ExecResult::ok(input) },
  )
  registry
}

///|
test "app server session tools expose read-only metadata" {
  let descriptor = find_app_server_session_tool("get_session_snapshot").unwrap()
  assert_true(descriptor.class == ReadOnly)
  assert_eq(descriptor.required_permissions.length(), 0)
  assert_true(
    str_index_of(descriptor.envelope.output, "AgentSessionSnapshot") is Some(_),
  )

  let registry = app_server_tool_boundary_test_registry()
  let session = Session::create("s-tools")
  let plan = plan_app_server_session_tool(
    session,
    registry,
    [],
    "get_session_snapshot",
  )
  assert_true(plan.known_tool)
  assert_true(!plan.mutates_session)
  assert_true(!plan.approval_required)
}

///|
test "app server session tools expose normal mutation metadata and apply helper" {
  let descriptor = find_app_server_session_tool("append_user_message").unwrap()
  assert_true(descriptor.class == NormalMutation)
  assert_eq(descriptor.envelope.input, "{\"content\":\"string\"}")

  let registry = app_server_tool_boundary_test_registry()
  let session = Session::create("s-normal")
    .apply_app_server_session_tool("start_session", EmptyInput)
    .unwrap()
    .apply_app_server_session_tool(
      "append_user_message",
      TextInput("hello from app server"),
    )
    .unwrap()
  assert_true(session.is_running())
  assert_eq(session.event_count(), 2)

  let plan = plan_app_server_session_tool(
    session,
    registry,
    [],
    "append_user_message",
  )
  assert_true(plan.known_tool)
  assert_true(plan.mutates_session)
  assert_true(!plan.approval_required)
  assert_eq(
    plan.reason,
    "normal mutation only records deterministic session events",
  )
}

///|
test "app server session tools expose approval-required metadata" {
  let descriptor = find_app_server_session_tool("execute_tool_request").unwrap()
  assert_true(descriptor.class == ApprovalRequired)
  assert_true(
    str_index_of(descriptor.description, "host-side execution") is Some(_),
  )

  let registry = app_server_tool_boundary_test_registry()
  let req = {
    tool_name: "write_file",
    input: "{\"path\":\"/workspace/out.txt\"}",
    call_id: "call-write",
  }
  let session = Session::create("s-approval")
    .start()
    .unwrap()
    .request_tool(req)
    .unwrap()
  let plan = plan_app_server_session_tool(
    session,
    registry,
    [],
    "execute_tool_request",
  )
  assert_true(plan.known_tool)
  assert_true(plan.mutates_session)
  assert_true(plan.approval_required)
  assert_eq(plan.required_permissions.length(), 1)
  assert_eq(plan.missing_permissions.length(), 1)

  let granted_plan = plan_app_server_session_tool(
    session,
    app_server_tool_boundary_test_registry(),
    [FileWrite("/workspace/out.txt")],
    "execute_tool_request",
  )
  assert_true(granted_plan.approval_required)
  assert_eq(granted_plan.missing_permissions.length(), 0)
}

///|
test "app server session tool catalog json is deterministic" {
  let json = app_server_session_tool_catalog_json()
  assert_true(
    str_index_of(
      json, "\"schema_version\":\"orbit.app_server.session_tools.v1\"",
    )
    is Some(_),
  )
  assert_true(
    str_index_of(
      json, "\"name\":\"get_session_snapshot\",\"class\":\"read_only\"",
    )
    is Some(_),
  )
  assert_true(
    str_index_of(
      json, "\"name\":\"append_user_message\",\"class\":\"normal_mutation\"",
    )
    is Some(_),
  )
  assert_true(
    str_index_of(
      json, "\"name\":\"execute_tool_request\",\"class\":\"approval_required\"",
    )
    is Some(_),
  )

  let registry = app_server_tool_boundary_test_registry()
  let session = Session::create("s-plan")
  let plan_json = plan_app_server_session_tool(
    session,
    registry,
    [],
    "missing_tool",
  ).to_json_string()
  assert_true(str_index_of(plan_json, "\"known_tool\":false") is Some(_))
  assert_true(str_index_of(plan_json, "\"approval_required\":true") is Some(_))
  assert_true(
    str_index_of(plan_json, "\"reason\":\"unknown App Server session tool\"")
    is Some(_),
  )
}
