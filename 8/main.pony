use "files"
use "itertools"
use "buffered"

primitive Black
  fun string(): String => "⬛️"
primitive White
  fun string(): String => "⬜️"
primitive Transparent
  fun string(): String => "_"

type Color is (Black | White | Transparent)
type Layer is Array[Color] val
type Image is Array[Color] val

actor Main
  let _wide: U64 = 25
  let _tall: U64 = 6

  fun from_ascii(i: U8): U8? =>
    match i
    | 48 => 0
    | 49 => 1
    | 50 => 2
    else error
    end

  fun to_color(i: U8): Color? =>
    match i
    | 0 => Black
    | 1 => White
    | 2 => Transparent
    else error
    end

  fun load_file(env: Env, path: String, default: Image): Image =>
    let r = Reader
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    try
      let file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
      let str = file.read_string(file.size())
      let arr = recover Image end
      r.append(consume str)
      while true do
        try
          let v = r.u8()?
          arr.push(to_color(from_ascii(v)?)?)
        else
          break
        end
      end
      file.dispose()
      arr
    else
      default
    end

  fun stack_colors(top: Color, bottom: Color): Color =>
    match top
    | Transparent => bottom
    else top
    end

  fun stack_layers(layer_size: USize, top: Layer ref, bottom: Layer ref)? =>
    var idx: USize = 0
    while idx < layer_size do
      top.update(idx, stack_colors(top(idx)?, bottom(idx)?))?
      idx = idx + 1
    end

  new create(env: Env) =>
    try
      let layer_size = (_wide * _tall).usize()
      let top_layer = Array[Color].init(Transparent, layer_size)

      let values = Iter[Color](load_file(env, "./8/input.txt", []).values())
      while values.has_next() do
        let bottom_layer = values.take(layer_size).collect(Layer)
        stack_layers(layer_size, top_layer, bottom_layer)?
      end

      var idx: USize = 0
      for v in top_layer.values() do
        if idx.u64().mod(_wide) == 0 then
          env.out.print("")
        end
        env.out.write(v.string())
        idx = idx + 1
      end
      env.out.print("")
    end

