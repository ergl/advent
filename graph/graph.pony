use "collections"

primitive GraphUtils
  fun euler_path[A: Comparable[A] val, H: HashFunction[A] val](
    from: A,
    graph: Graph[A, H] box)
    : Array[A] iso^
  =>
    let copy: Graph[A, H] ref = graph.clone()
    try _euler_path[A, H](from, copy.neighbors(from), copy, recover Array[A] end)? else [] end

  fun _euler_path[A: Comparable[A] val, H: HashFunction[A] val](
    from: A,
    edges_iter: Iterator[A],
    graph: Graph[A, H],
    path_acc: Array[A] iso)
    : Array[A] iso^?
  =>
    if not edges_iter.has_next() then
      consume path_acc
    else
      // Can't fail, we asked if there was more
      let to = edges_iter.next()?
      if graph._is_valid_edge(from, to) then
        graph.remove_edge(from, to)
        path_acc.push(to)
        _euler_path[A, H](to, graph.neighbors(to), graph, consume path_acc)?
      else
        _euler_path[A, H](from, edges_iter, graph, consume path_acc)?
      end
    end

  fun euler_path_naive[A: Comparable[A] val, H: HashFunction[A] val](
    from: A,
    graph: Graph[A, H] box)
    : Array[A] ref
  =>
    let copy: Graph[A, H] ref = graph.clone()
    let e_path = Array[A]
    _euler_path_naive[A, H](from, copy, e_path)
    e_path

  fun _euler_path_naive[A: Comparable[A] val, H: HashFunction[A] val](
    from: A,
    graph: Graph[A, H],
    path_acc: Array[A])
  =>
    for to in graph.neighbors(from) do
      if graph._is_valid_edge(from, to) then
        path_acc.push(to)
        graph.remove_edge(from, to)
        _euler_path_naive[A, H](to, graph, path_acc)
      end
    end

type GraphIs[A: Comparable[A] val] is Graph[A, HashIs[A]]

class Graph[A: Comparable[A] val, H: HashFunction[A] val]
  embed _backing_store: HashMap[A, Array[A], H]
  embed _heap: TunableHeap[A]
  embed _in_heap: HashSet[A, H]
  embed _distances: HashMap[A, U64, H]
  embed _came_from: HashMap[A, A, H]

  new create() =>
    _backing_store = HashMap[A, Array[A], H]
    _heap = TunableHeap[A]
    _in_heap = HashSet[A, H]
    _distances = HashMap[A, U64, H]
    _came_from = HashMap[A, A, H]

  fun ref add_vertex(v: A) =>
    _backing_store.insert_if_absent(v, [])

  fun is_vertex(v: A): Bool =>
    _backing_store.contains(v)

  fun neighbors(v: A): Iterator[this->A] =>
    _backing_store.get_or_else(v, []).values()

  fun degree(v: A): USize =>
    _backing_store.get_or_else(v, []).size()

  fun vertices(): Iterator[this->A] =>
    _backing_store.keys()

  fun ref add_edge(v1: A, v2: A) =>
    _backing_store.upsert(v1, [v2], this~_add_to_array())
    _backing_store.upsert(v2, [v1], this~_add_to_array())

  fun _add_to_array(current: Array[A] ref, provided: Array[A] ref): Array[A] ref =>
    try
      let given_vertex = provided(0)? // Given bare array
      if not current.contains(given_vertex, {(l, r) => l == r}) then
        current.push(given_vertex)
      end
    end
    current

  fun ref farthest_point(from: A): ((A, USize) | None) =>
    var path_size: USize = 0
    var point: (A | None) = None
    for vertex in _backing_store.keys() do
      if vertex.ne(from) then
        let size = path(from, vertex).size()
        if size > path_size then
          path_size = size
          point = vertex
        end
      end
    end

    try (point as A, path_size) end

  fun reachable_from(from: A): USize =>
    _reachable(from, HashSet[A, H])

  fun _reachable(from: A, visited: HashSet[A, H]): USize =>
    var count: USize = 1
    visited.set(from)
    let v_edges = _backing_store.get_or_else(from, [])
    for v in v_edges.values() do
      if not visited.contains(v) then
        count = count + _reachable(v, visited)
      end
    end
    count

  fun ref _is_valid_edge(from: A, to: A): Bool =>
    if _backing_store.get_or_else(from, []).size() == 1 then
      true
    else
      let visited = HashSet[A, H]
      let before = _reachable(from, visited)

      visited.clear()
      // Remove it, so we can check
      remove_edge(from, to)
      let after = _reachable(from, visited)
      // And add it again
      add_edge(from, to)
      after >= before
    end

  fun ref remove_edge(from: A, to: A) =>
    let from_edges = _backing_store.get_or_else(from, [])
    let to_edges = _backing_store.get_or_else(to, [])
    try
      from_edges.delete(from_edges.find(to where predicate = {(found, given) => found == given})?)?
      to_edges.delete(to_edges.find(from where predicate = {(found, given) => found == given})?)?
    end

  fun clone(): Graph[A, H] iso^ =>
    let g = recover Graph[A, H] end
    for (k, edges) in _backing_store.pairs() do
      g.add_vertex(k)
      for v in edges.values() do
        g.add_vertex(v)
        g.add_edge(k, v)
      end
    end
    consume g

  fun ref path(from: A, to: A): Array[A] val =>
    _heap.clear()
    _in_heap.clear()
    _distances.clear()
    _came_from.clear()

    _came_from.insert(from, from)
    _in_heap.set(from)
    _heap.push(from, 0)
    _distances.insert(from, 0)

    let steps = recover Array[A] end
    try
      while _heap.size() != 0 do
        let head = _heap.pop()?
        _in_heap.unset(head)

        if head.eq(to) then
          var previous = head
          while previous.ne(from) and _came_from.contains(previous) do
            steps.push(previous)
            previous = _came_from(previous)?
          end
          break
        end

        for neighbor in _backing_store(head)?.values() do
          let my_distance = _distances.get_or_else(head, U64.max_value())
          let old_distance = _distances.get_or_else(neighbor, U64.max_value())
          let new_distance = try my_distance +? 1 else U64.max_value() end
          if new_distance < old_distance then
            _distances.insert(neighbor, new_distance)
            _came_from.insert(neighbor, head)
            if not _in_heap.contains(neighbor) then
              _heap.push(neighbor, new_distance)
              _in_heap.set(neighbor)
            end
          end
        end

      end
    end

    steps.reverse_in_place()
    consume steps
