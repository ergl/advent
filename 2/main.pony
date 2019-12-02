use "files"
use "itertools"

actor Main
  var path: String = "./2/input.txt"
  let example: Array[U64] = [1;9;10;3;2;3;11;0;99;30;40;50]

  fun _parse_input(input: String val): U64 =>
    try input.u64()? else 0 end

  fun _solve(program: Array[U64] ref): None =>
    try
      var pc: USize = 0
      var opcode = program(pc)?

      while opcode != 99 do
        let src_l = program(program(pc + 1)?.usize())?
        let src_r = program(program(pc + 2)?.usize())?

        let target_p = program(pc + 3)?.usize()
        let target = program(target_p)?

        let result = match opcode
          | 1 => src_l + src_r
          | 2 => src_l * src_r
          else
            target
          end
        program.update(target_p, result)?
        pc = pc + 4
        opcode = program(pc)?
      end

    else
      None
    end

  fun _print_program(env: Env, program: Array[U64]): None =>
    for num in program.values() do
          env.out.print(num.string())
    end

  new create(env: Env) =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end

    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
      do
        let program: Array[U64] ref = Iter[String](file.read_string(file.size()).split_by(",").values())
                        .map[U64]({(elt)(that=this) => that._parse_input(elt)})
                        .collect(Array[U64](10))


        program.update(1, 12)?
        program.update(2, 2)?
        _solve(program)
        _print_program(env, program)
      end
    else
      env.out.print("Couldn't open ".add(path))
    end
