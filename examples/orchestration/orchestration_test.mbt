///|
test "fizzbuzz_scenario has correct number of tasks" {
  let orch = fizzbuzz_scenario()
  assert_eq(orch.task_graph.node_count(), 5)
}

///|
test "fizzbuzz task dependency order is valid (no cycles)" {
  let orch = fizzbuzz_scenario()
  assert_true(!orch.task_graph.has_cycle())
  let order = orch.task_graph.topological_order().unwrap()
  assert_eq(order.length(), 5)
}

///|
test "adding a cycle is detected" {
  let n1 : @orbit.TaskNode = {
    id: "a",
    description: "Task A",
    role: @orbit.Planner,
    dependencies: ["b"],
  }
  let n2 : @orbit.TaskNode = {
    id: "b",
    description: "Task B",
    role: @orbit.Executor,
    dependencies: ["a"],
  }
  let graph = @orbit.TaskGraph::create()
    .add_node(n1)
    .unwrap()
    .add_node(n2)
    .unwrap()
  assert_true(graph.has_cycle())
  assert_true(graph.topological_order() is Err(_))
}

///|
test "run_scenario produces one snapshot per task" {
  let orch = fizzbuzz_scenario()
  let snapshots = run_scenario(orch)
  assert_eq(snapshots.length(), 5)
}

///|
test "snapshot can reconstruct same task count" {
  let orch = fizzbuzz_scenario()
  let snapshots = run_scenario(orch)
  let last = snapshots[snapshots.length() - 1]
  let json = last.to_json_string()
  let parsed = @orbit.session_snapshot_from_json(json)
  match parsed {
    Some(snap) => {
      assert_eq(snap.tasks.length(), 5)
      assert_eq(snap.agents.length(), 3)
    }
    None => assert_true(false)
  }
}
