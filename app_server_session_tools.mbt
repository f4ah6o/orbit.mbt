///|
/// Transport-free App Server session tool boundary.
///
/// These descriptors are data contracts for native, wasm, WebView, or HTTP
/// adapters. The runtime only describes and plans session operations; adapters
/// remain responsible for transport, UI approval prompts, and host execution.

///|
fn app_server_tool_boundary_version() -> String {
  "orbit.app_server.session_tools.v1"
}

///|
pub(all) enum AppServerSessionToolClass {
  ReadOnly
  NormalMutation
  ApprovalRequired
} derive(Debug, Eq)

///|
pub(all) struct AppServerSessionToolEnvelope {
  input : String
  output : String
} derive(Debug, Eq)

///|
pub(all) struct AppServerSessionToolDescriptor {
  name : String
  class : AppServerSessionToolClass
  description : String
  envelope : AppServerSessionToolEnvelope
  required_permissions : Array[Permission]
} derive(Debug, Eq)

///|
pub(all) struct AppServerSessionToolPlan {
  schema_version : String
  tool_name : String
  class : AppServerSessionToolClass
  known_tool : Bool
  mutates_session : Bool
  approval_required : Bool
  required_permissions : Array[Permission]
  missing_permissions : Array[Permission]
  reason : String
} derive(Debug, Eq)

///|
pub(all) enum AppServerSessionToolInput {
  EmptyInput
  TextInput(String)
  ToolRequestInput(ToolRequest)
  ToolResponseInput(ToolResponse)
} derive(Debug, Eq)

///|
fn AppServerSessionToolClass::to_json_string(
  self : AppServerSessionToolClass,
) -> String {
  match self {
    ReadOnly => "read_only"
    NormalMutation => "normal_mutation"
    ApprovalRequired => "approval_required"
  }
}

///|
fn AppServerSessionToolEnvelope::to_json_string(
  self : AppServerSessionToolEnvelope,
) -> String {
  "{\"input\":\"" +
  escape_json(self.input) +
  "\",\"output\":\"" +
  escape_json(self.output) +
  "\"}"
}

///|
fn AppServerSessionToolDescriptor::to_json_string(
  self : AppServerSessionToolDescriptor,
) -> String {
  "{\"name\":\"" +
  escape_json(self.name) +
  "\",\"class\":\"" +
  self.class.to_json_string() +
  "\",\"description\":\"" +
  escape_json(self.description) +
  "\",\"envelope\":" +
  self.envelope.to_json_string() +
  ",\"required_permissions\":" +
  permissions_to_json(self.required_permissions) +
  "}"
}

///|
fn app_server_session_tool_descriptors_to_json(
  tools : Array[AppServerSessionToolDescriptor],
) -> String {
  let mut buf = "["
  let mut first = true
  for tool in tools {
    if first {
      buf = buf + tool.to_json_string()
      first = false
    } else {
      buf = buf + "," + tool.to_json_string()
    }
  }
  buf + "]"
}

///|
pub fn AppServerSessionToolPlan::to_json_string(
  self : AppServerSessionToolPlan,
) -> String {
  "{\"schema_version\":\"" +
  escape_json(self.schema_version) +
  "\",\"tool_name\":\"" +
  escape_json(self.tool_name) +
  "\",\"class\":\"" +
  self.class.to_json_string() +
  "\",\"known_tool\":" +
  (if self.known_tool { "true" } else { "false" }) +
  ",\"mutates_session\":" +
  (if self.mutates_session { "true" } else { "false" }) +
  ",\"approval_required\":" +
  (if self.approval_required { "true" } else { "false" }) +
  ",\"required_permissions\":" +
  permissions_to_json(self.required_permissions) +
  ",\"missing_permissions\":" +
  permissions_to_json(self.missing_permissions) +
  ",\"reason\":\"" +
  escape_json(self.reason) +
  "\"}"
}

///|
fn read_only_session_tool_descriptors() -> Array[AppServerSessionToolDescriptor] {
  [
    {
      name: "get_session_snapshot",
      class: ReadOnly,
      description: "Return the current AgentSessionSnapshot JSON.",
      envelope: {
        input: "{\"session_id\":\"string\"}",
        output: "{\"snapshot\":AgentSessionSnapshot}",
      },
      required_permissions: [],
    },
    {
      name: "export_replay",
      class: ReadOnly,
      description: "Return the replay export artifact for a session.",
      envelope: {
        input: "{\"session_id\":\"string\"}",
        output: "{\"replay_export\":ReplayExportEnvelope}",
      },
      required_permissions: [],
    },
    {
      name: "list_session_tools",
      class: ReadOnly,
      description: "Return this transport-free session tool catalog.",
      envelope: {
        input: "{\"session_id\":\"string\"}",
        output: "{\"tools\":AppServerSessionToolDescriptor[]}",
      },
      required_permissions: [],
    },
  ]
}

///|
fn normal_mutation_session_tool_descriptors() -> Array[
  AppServerSessionToolDescriptor,
] {
  [
    {
      name: "start_session",
      class: NormalMutation,
      description: "Append SessionStarted and move an idle session to running.",
      envelope: { input: "{}", output: "{\"snapshot\":AgentSessionSnapshot}" },
      required_permissions: [],
    },
    {
      name: "end_session",
      class: NormalMutation,
      description: "Append SessionEnded and move a running session to idle.",
      envelope: { input: "{}", output: "{\"snapshot\":AgentSessionSnapshot}" },
      required_permissions: [],
    },
    {
      name: "append_user_message",
      class: NormalMutation,
      description: "Append a user message event to a running session.",
      envelope: {
        input: "{\"content\":\"string\"}",
        output: "{\"snapshot\":AgentSessionSnapshot}",
      },
      required_permissions: [],
    },
    {
      name: "append_assistant_message",
      class: NormalMutation,
      description: "Append an assistant message event to a running session.",
      envelope: {
        input: "{\"content\":\"string\"}",
        output: "{\"snapshot\":AgentSessionSnapshot}",
      },
      required_permissions: [],
    },
    {
      name: "record_tool_request",
      class: NormalMutation,
      description: "Append ToolCall and enter WaitingTool without host execution.",
      envelope: {
        input: "{\"tool_name\":\"string\",\"input\":\"string\",\"call_id\":\"string\"}",
        output: "{\"snapshot\":AgentSessionSnapshot}",
      },
      required_permissions: [],
    },
    {
      name: "record_tool_result",
      class: NormalMutation,
      description: "Append ToolResult after an adapter supplies a result.",
      envelope: {
        input: "{\"call_id\":\"string\",\"output\":\"string\",\"success\":boolean}",
        output: "{\"snapshot\":AgentSessionSnapshot}",
      },
      required_permissions: [],
    },
    {
      name: "record_failure",
      class: NormalMutation,
      description: "Append a failure reason and move the session to failed.",
      envelope: {
        input: "{\"reason\":\"string\"}",
        output: "{\"snapshot\":AgentSessionSnapshot}",
      },
      required_permissions: [],
    },
    {
      name: "record_stream_chunk",
      class: NormalMutation,
      description: "Append a streamed assistant chunk as a replayable event.",
      envelope: {
        input: "{\"chunk\":\"string\"}",
        output: "{\"snapshot\":AgentSessionSnapshot}",
      },
      required_permissions: [],
    },
  ]
}

///|
fn approval_required_session_tool_descriptors() -> Array[
  AppServerSessionToolDescriptor,
] {
  [
    {
      name: "approve_tool_request",
      class: ApprovalRequired,
      description: "Record adapter approval intent for the pending tool request.",
      envelope: {
        input: "{\"call_id\":\"string\",\"granted_permissions\":Permission[]}",
        output: "{\"plan\":AppServerSessionToolPlan}",
      },
      required_permissions: [],
    },
    {
      name: "execute_tool_request",
      class: ApprovalRequired,
      description: "Plan host-side execution for the pending registered tool.",
      envelope: {
        input: "{\"call_id\":\"string\"}",
        output: "{\"plan\":AppServerSessionToolPlan}",
      },
      required_permissions: [],
    },
    {
      name: "grant_permission",
      class: ApprovalRequired,
      description: "Plan a session permission grant handled by the adapter.",
      envelope: {
        input: "{\"permission\":Permission}",
        output: "{\"plan\":AppServerSessionToolPlan}",
      },
      required_permissions: [],
    },
  ]
}

///|
pub fn app_server_session_tool_descriptors() -> Array[
  AppServerSessionToolDescriptor,
] {
  let tools : Array[AppServerSessionToolDescriptor] = []
  for tool in read_only_session_tool_descriptors() {
    tools.push(tool)
  }
  for tool in normal_mutation_session_tool_descriptors() {
    tools.push(tool)
  }
  for tool in approval_required_session_tool_descriptors() {
    tools.push(tool)
  }
  tools
}

///|
pub fn app_server_session_tool_catalog_json() -> String {
  "{\"schema_version\":\"" +
  app_server_tool_boundary_version() +
  "\",\"tools\":" +
  app_server_session_tool_descriptors_to_json(
    app_server_session_tool_descriptors(),
  ) +
  "}"
}

///|
pub fn find_app_server_session_tool(
  name : String,
) -> AppServerSessionToolDescriptor? {
  for tool in app_server_session_tool_descriptors() {
    if tool.name == name {
      return Some(tool)
    }
  }
  None
}

///|
fn required_permissions_for_tool_plan(
  name : String,
  session : Session,
  registry : ToolRegistry,
) -> Array[Permission] {
  if name != "execute_tool_request" && name != "approve_tool_request" {
    return []
  }
  required_permissions_for_pending_tool(session, Some(registry))
}

///|
pub fn plan_app_server_session_tool(
  session : Session,
  registry : ToolRegistry,
  granted_permissions : Array[Permission],
  name : String,
) -> AppServerSessionToolPlan {
  match find_app_server_session_tool(name) {
    Some(tool) => {
      let required = required_permissions_for_tool_plan(
        tool.name,
        session,
        registry,
      )
      let missing = missing_permissions(required, granted_permissions)
      let needs_approval = tool.class == ApprovalRequired ||
        missing.length() > 0
      {
        schema_version: app_server_tool_boundary_version(),
        tool_name: tool.name,
        class: tool.class,
        known_tool: true,
        mutates_session: tool.class != ReadOnly,
        approval_required: needs_approval,
        required_permissions: required,
        missing_permissions: missing,
        reason: if needs_approval {
          "tool crosses the App Server approval boundary"
        } else if tool.class == ReadOnly {
          "read-only tool does not mutate session or host resources"
        } else {
          "normal mutation only records deterministic session events"
        },
      }
    }
    None =>
      {
        schema_version: app_server_tool_boundary_version(),
        tool_name: name,
        class: ReadOnly,
        known_tool: false,
        mutates_session: false,
        approval_required: true,
        required_permissions: [],
        missing_permissions: [],
        reason: "unknown App Server session tool",
      }
  }
}

///|
pub fn Session::apply_app_server_session_tool(
  self : Session,
  name : String,
  input : AppServerSessionToolInput,
) -> Result[Session, String] {
  match name {
    "start_session" => self.start()
    "end_session" => self.end()
    "append_user_message" =>
      match input {
        TextInput(content) => self.send_user_message(content)
        _ => Err("append_user_message expects TextInput")
      }
    "append_assistant_message" =>
      match input {
        TextInput(content) => self.receive_assistant_message(content)
        _ => Err("append_assistant_message expects TextInput")
      }
    "record_tool_request" =>
      match input {
        ToolRequestInput(req) => self.request_tool(req)
        _ => Err("record_tool_request expects ToolRequestInput")
      }
    "record_tool_result" =>
      match input {
        ToolResponseInput(res) => self.respond_tool(res)
        _ => Err("record_tool_result expects ToolResponseInput")
      }
    "record_failure" =>
      match input {
        TextInput(reason) => Ok(self.fail(reason))
        _ => Err("record_failure expects TextInput")
      }
    "record_stream_chunk" =>
      match input {
        TextInput(chunk) => Ok(self.apply(StreamChunk(chunk)))
        _ => Err("record_stream_chunk expects TextInput")
      }
    _ => Err("tool is not a normal session mutation: " + name)
  }
}
