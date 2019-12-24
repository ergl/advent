use "collections"

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
