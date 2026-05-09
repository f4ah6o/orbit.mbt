///|
/// A registered tool entry — wraps metadata and execute function.
struct ToolEntry {
  name : String
  metadata : ToolMetadata
  execute_fn : (String) -> ExecResult
}

///|
/// ToolRegistry — stores and retrieves tools by name.
/// Tools are registered with their metadata and execution function.
pub struct ToolRegistry {
  mut entries : Array[ToolEntry]
}

///|
/// Create an empty tool registry.
pub fn ToolRegistry::create() -> ToolRegistry {
  { entries: [] }
}

///|
/// Register a tool by name, metadata, and execute function.
/// If a tool with the same name exists, it is replaced.
pub fn ToolRegistry::register(
  self : ToolRegistry,
  name : String,
  metadata : ToolMetadata,
  execute_fn : (String) -> ExecResult,
) -> Unit {
  let new_entries : Array[ToolEntry] = []
  for entry in self.entries {
    if entry.name != name {
      new_entries.push(entry)
    }
  }
  new_entries.push({ name, metadata, execute_fn })
  self.entries = new_entries
}

///|
/// Register any Tool implementation into the registry.
pub fn[T : Tool] ToolRegistry::register_tool(
  self : ToolRegistry,
  tool : T,
) -> Unit {
  let meta = tool.metadata()
  let name = meta.name
  self.register(name, meta, fn(input) { tool.execute(input) })
}

///|
/// Look up a tool by name. Returns the tool metadata if found.
pub fn ToolRegistry::lookup(
  self : ToolRegistry,
  name : String,
) -> ToolMetadata? {
  for entry in self.entries {
    if entry.name == name {
      return Some(entry.metadata)
    }
  }
  None
}

///|
/// Check if a tool is registered by name.
pub fn ToolRegistry::has_tool(self : ToolRegistry, name : String) -> Bool {
  for entry in self.entries {
    if entry.name == name {
      return true
    }
  }
  false
}

///|
/// Execute a tool by name with the given input.
/// Returns Ok(ExecResult) if the tool exists, Err(msg) if not found.
pub fn ToolRegistry::execute(
  self : ToolRegistry,
  name : String,
  input : String,
) -> Result[ExecResult, String] {
  for entry in self.entries {
    if entry.name == name {
      return Ok((entry.execute_fn)(input))
    }
  }
  Err("tool not found: " + name)
}

///|
/// List all registered tool names.
pub fn ToolRegistry::list_tools(self : ToolRegistry) -> Array[String] {
  let names : Array[String] = []
  for entry in self.entries {
    names.push(entry.name)
  }
  names
}
