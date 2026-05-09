///|
/// If the session is WaitingTool, dispatch the pending tool call
/// through the registry and return the updated session.
/// Otherwise return the session unchanged.
pub fn step(
  session : @orbit.Session,
  registry : @orbit.ToolRegistry,
) -> @orbit.Session {
  match session.current_state() {
    @orbit.WaitingTool(_, req) => {
      let result = registry.execute(req.tool_name, req.input)
      let response : @orbit.ToolResponse = match result {
        Ok(exec) =>
          {
            call_id: req.call_id,
            output: exec.output,
            success: exec.success,
          }
        Err(msg) =>
          {
            call_id: req.call_id,
            output: msg,
            success: false,
          }
      }
      match session.respond_tool(response) {
        Ok(s) => s
        Err(_) => session
      }
    }
    _ => session
  }
}
