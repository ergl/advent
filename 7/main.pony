use "files"
use "itertools"

primitive Utils
  fun parse_input(input: String): I64 =>
    try input.i64()? else 0 end

  fun to_string(arr: Array[I64]): String =>
    Iter[I64](arr.values())
      .fold[String]("[", {(acc, elt) => acc.add(elt.string().add(";"))}).add("]")

  fun permutations(input: Array[I64]): Array[Array[I64]]? =>
    let acc = Array[Array[I64]].create()
    _permute(input, 0, acc)?
    acc

  fun _permute(input: Array[I64], k: USize, acc: Array[Array[I64]])? =>
    let size = input.size()
    var idx = k
    while idx < size do
      input.swap_elements(idx, k)?
      _permute(input, k + 1, acc)?
      input.swap_elements(k, idx)?
      idx = idx + 1
    end

    if k == (size - 1) then
      let input_clone = recover Array[I64].create() end
      for elt in input.values() do
        input_clone.push(elt)
      end
      acc.push(consume input_clone)
    end

actor Main
  var path: String = "./7/input.txt"

  fun ref run_for_combination(program_mem: Array[I64] val, settings: Array[I64]): I64? =>
    let stdin = IOQueue.create().>put(settings(0)?).>put(0)
    let std_io_1 = IOQueue.create().>put(settings(1)?)
    let std_io_2 = IOQueue.create().>put(settings(2)?)
    let std_io_3 = IOQueue.create().>put(settings(3)?)
    let std_io_4 = IOQueue.create().>put(settings(4)?)
    let stdout = IOQueue.create()

    let program_a = Program.create(stdin, std_io_1, program_mem)
    let program_b = Program.create(std_io_1, std_io_2, program_mem)
    let program_c = Program.create(std_io_2, std_io_3, program_mem)
    let program_d = Program.create(std_io_3, std_io_4, program_mem)
    let program_e = Program.create(std_io_4, stdout, program_mem)

    while not program_a.finished do
      program_a.step()
    end

    while not program_b.finished do
      program_b.step()
    end

    while not program_c.finished do
      program_c.step()
    end

    while not program_d.finished do
      program_d.step()
    end

    while not program_e.finished do
      program_e.step()
    end

    match stdout.get()
    | None => error
    | let i: I64 => i
    end

  new create(env: Env) =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
      do
        let program_arr: Array[I64] val = recover val
          Iter[String](file.read_string(file.size()).split_by(",").values())
            .map[I64]({(elt) => Utils.parse_input(elt)})
            .collect(Array[I64](10))
        end

        var answer: I64 = 0
        var max_so_far: I64 = 0
        let arrs = Utils.permutations([as I64: 0; 1; 2; 3; 4])?
        for phase_arr in arrs.values() do
          env.out.print("Try: ".add(Utils.to_string(phase_arr)))

          answer = run_for_combination(program_arr, phase_arr)?
          env.out.print("Answer: ".add(answer.string()))

          max_so_far = max_so_far.max(answer)
          env.out.print("Max so far is ".add(max_so_far.string()))
        end

        env.out.print("Max is ".add(max_so_far.string()))
      end
    else
      env.out.print("Couldn't open ".add(path))
    end
