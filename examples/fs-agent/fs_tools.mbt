///|
/// ReadFileTool — reads a file from the VFS.
/// Requires permission: FileRead("*").
pub(all) struct ReadFileTool {
  vfs : Ref[VFS]
}

///|
pub fn ReadFileTool::metadata(self : ReadFileTool) -> @orbit.ToolMetadata {
  let _ = self
  {
    name: "read_file",
    description: "Reads a file from the virtual filesystem",
    permissions: [@orbit.FileRead("*")],
    version: "1.0.0",
  }
}

///|
pub fn ReadFileTool::execute(
  self : ReadFileTool,
  input : String,
) -> @orbit.ExecResult {
  match self.vfs.val.read(input) {
    Ok(content) => @orbit.ExecResult::ok(content)
    Err(msg) => @orbit.ExecResult::fail(msg)
  }
}

///|
/// WriteFileTool — writes content to the VFS.
/// Input format: "path:content".
/// Requires permission: FileWrite("*").
pub(all) struct WriteFileTool {
  vfs : Ref[VFS]
}

///|
pub fn WriteFileTool::metadata(self : WriteFileTool) -> @orbit.ToolMetadata {
  let _ = self
  {
    name: "write_file",
    description: "Writes content to the virtual filesystem",
    permissions: [@orbit.FileWrite("*")],
    version: "1.0.0",
  }
}

///|
pub fn WriteFileTool::execute(
  self : WriteFileTool,
  input : String,
) -> @orbit.ExecResult {
  let mut colon = -1
  let mut i = 0
  while i < input.length() {
    if input[i] == ':' {
      colon = i
      break
    }
    i = i + 1
  }
  if colon < 0 {
    return @orbit.ExecResult::fail(
      "invalid input format, expected 'path:content'",
    )
  }
  let path = input[0:colon].to_owned()
  let end = input.length()
  let content = input[colon + 1:end].to_owned()
  self.vfs.val = self.vfs.val.write(path, content)
  @orbit.ExecResult::ok("wrote " + path)
}

///|
/// ListDirTool — lists files under a directory in the VFS.
/// Requires permission: FileRead("*").
pub(all) struct ListDirTool {
  vfs : Ref[VFS]
}

///|
pub fn ListDirTool::metadata(self : ListDirTool) -> @orbit.ToolMetadata {
  let _ = self
  {
    name: "list_dir",
    description: "Lists files under a directory in the virtual filesystem",
    permissions: [@orbit.FileRead("*")],
    version: "1.0.0",
  }
}

///|
pub fn ListDirTool::execute(
  self : ListDirTool,
  input : String,
) -> @orbit.ExecResult {
  let entries = self.vfs.val.list(input)
  let mut output = ""
  let mut first = true
  for entry in entries {
    if first {
      output = entry
      first = false
    } else {
      output = output + "\n" + entry
    }
  }
  @orbit.ExecResult::ok(output)
}
