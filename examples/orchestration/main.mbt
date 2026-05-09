///|
fn main {
  let orch = fizzbuzz_scenario()
  let order = orch.task_graph.topological_order().unwrap()
  println("Task graph: " + orch.task_graph.node_count().to_string() + " nodes")
  println("")
  let snapshots = run_scenario(orch)
  let mut i = 0
  while i < order.length() {
    println("  => " + order[i].id + ": " + order[i].description)
    i = i + 1
  }
  println("")
  println("Snapshots: " + snapshots.length().to_string())
  println(
    "Final snapshot tasks: " +
    snapshots[snapshots.length() - 1].tasks.length().to_string(),
  )
}
