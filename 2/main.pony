use "files"
use "itertools"

actor Main
  var path: String = "./2/input.txt"
  let example: Array[U64] = [1;9;10;3;2;3;11;0;99;30;40;50]
  let program_result: U64 = 19690720

  fun tag _parse_input(input: String val): U64 =>
    try input.u64()? else 0 end

  fun _run_program(noun: U64, verb: U64, program: Array[U64] ref): U64 =>
    try
      program.update(1, noun)?
      program.update(2, verb)?

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

      program(0)?
    else
      -1
    end

  fun _solve(program: Array[U64] val): (U64, U64) =>
    let program_size = program.size()
    let copy = Array[U64].create(program.size())
    program.copy_to(copy, 0, 0, program_size)

    var noun: U64 = 0
    var verb: U64 = 0

    while _run_program(noun, verb, copy) != program_result do
      // Reset the memory
      program.copy_to(copy, 0, 0, program_size)

      verb = verb + 1
      if verb == 100 then
        if noun == 99 then
          break
        else
          noun = noun + 1
          verb = 0
        end
      end
    end

    (noun, verb)

  new create(env: Env) =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end

    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
      do
        let program: Array[U64] val = recover val
          Iter[String](file.read_string(file.size()).split_by(",").values())
            .map[U64]({(elt)(that=this) => that._parse_input(elt)})
            .collect(Array[U64](10))
        end

        let noun_verb = _solve(program)
        let answer = (100 * noun_verb._1) + noun_verb._2
        env.out.print(answer.string())
      end
    else
      env.out.print("Couldn't open ".add(path))
    end
