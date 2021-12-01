use "files"
use "itertools"

primitive Black
  fun string(): String => "⬛️"
primitive White
  fun string(): String => "⬜️"
primitive Transparent
  fun string(): String => "_"

type Color is (Black | White | Transparent)
type Layer is Array[Color] val
type Image is Array[Color] val

primitive Utils
  fun process_file(env: Env, path: String, layer_size: USize, layer_buff: Layer ref) =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    try
      let file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
      let file_size = file.size()
      var cursor = file.position()
      while cursor < file_size do
        let color_buffer = Iter[U8](file.read(layer_size).values())
          .map[Color]({(elt)? => Colors.to_color(elt)?})
          .collect(Layer)

        Colors.stack_layers(layer_size, layer_buff, color_buffer)?
        cursor = file.position()
      end
      file.dispose()
    else
      env.out.print("Process error")
    end

primitive Colors
  fun _from_ascii(i: U8): U8? =>
    match i
    | 48 => 0
    | 49 => 1
    | 50 => 2
    else error
    end

  fun _to_color(i: U8): Color? =>
    match i
    | 0 => Black
    | 1 => White
    | 2 => Transparent
    else error
    end

  fun to_color(i: U8): Color? =>
    _to_color(_from_ascii(i)?)?

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

actor Main
  let _wide: U64 = 46
  let _tall: U64 = 36

  new create(env: Env) =>
    let layer_size = (_wide * _tall).usize()
    let top_layer = recover val
      let inner: Layer ref = Layer.init(Transparent, layer_size)
      Utils.process_file(env, "./08/big_boy.txt", layer_size, inner)
      inner
    end

    let string = recover
      let inner = String.create()
      var idx: USize = 0
      for v in top_layer.values() do
        if idx.u64().mod(_wide) == 0 then
          inner.push('\n')
        end
        inner.concat(v.string().values())
        idx = idx + 1
      end
      inner.push('\n')
      inner
    end

    env.out.print(consume string)
