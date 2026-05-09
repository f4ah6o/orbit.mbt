///|
/// In-memory virtual filesystem backed by a list of (path, content) pairs.
pub struct VFS {
  files : Array[(String, String)]
} derive(Debug, Eq)

///|
pub fn VFS::new() -> VFS {
  { files: [] }
}

///|
pub fn VFS::read(self : VFS, path : String) -> Result[String, String] {
  let _ = self
  for pair in self.files {
    let p = pair.0
    let content = pair.1
    if p == path {
      return Ok(content)
    }
  }
  Err("file not found: " + path)
}

///|
pub fn VFS::write(self : VFS, path : String, content : String) -> VFS {
  let _ = self
  let new_files : Array[(String, String)] = []
  let mut found = false
  for pair in self.files {
    let p = pair.0
    let c = pair.1
    if p == path {
      new_files.push((path, content))
      found = true
    } else {
      new_files.push((p, c))
    }
  }
  if !found {
    new_files.push((path, content))
  }
  { files: new_files }
}

///|
pub fn VFS::list(self : VFS, dir : String) -> Array[String] {
  let _ = self
  let entries : Array[String] = []
  let prefix = dir + "/"
  for pair in self.files {
    let p = pair.0
    let matched = if p.length() >= prefix.length() {
      let mut ok = true
      let mut i = 0
      while i < prefix.length() {
        if p[i] != prefix[i] {
          ok = false
          break
        }
        i = i + 1
      }
      ok
    } else {
      false
    }
    if matched {
      entries.push(p)
    }
  }
  entries
}
