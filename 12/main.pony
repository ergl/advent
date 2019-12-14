use "files"
use "itertools"
use "collections"

type Coord is (I64, I64, I64)
type Velocity is (I64, I64, I64)

class Moon
  var pos_x: I64
  var pos_y: I64
  var pos_z: I64
  var velocity_x: I64
  var velocity_y: I64
  var velocity_z: I64

  new create(pos': Coord) =>
    pos_x = pos'._1
    pos_y = pos'._2
    pos_z = pos'._3
    velocity_x = 0
    velocity_y = 0
    velocity_z = 0

  new with_velocity(pos': Coord, velocity': Velocity) =>
    pos_x = pos'._1
    pos_y = pos'._2
    pos_z = pos'._3
    velocity_x = velocity'._1
    velocity_y = velocity'._2
    velocity_z = velocity'._3

  fun ref step() =>
    pos_x = pos_x + velocity_x
    pos_y = pos_y + velocity_y
    pos_z = pos_z + velocity_z

  fun potential(): U64 =>
      pos_x.abs() + pos_y.abs() + pos_z.abs()

  fun kinetic(): U64 =>
    velocity_x.abs() + velocity_y.abs() + velocity_z.abs()

  fun energy(): U64 =>
    potential() * kinetic()

  fun string(): String =>
    recover
      let s = String.create()
      s.append("pos=(")
      s.append(pos_x.string())
      s.append(", ")
      s.append(pos_y.string())
      s.append(", ")
      s.append(pos_z.string())
      s.append("), ")
      s.append("vel=(")
      s.append(velocity_x.string())
      s.append(", ")
      s.append(velocity_y.string())
      s.append(", ")
      s.append(velocity_z.string())
      s.append(")")
      s
    end

primitive Utils
  fun parse_coord(str: String): Coord =>
    try
      let assignments = str.split(",>")
      let x = assignments(0)?.split("=")(1)?.i64()?
      let y = assignments(1)?.split("=")(1)?.i64()?
      let z = assignments(2)?.split("=")(1)?.i64()?
      (x, y, z)
    else
      (0, 0, 0)
    end

  fun into_arr(env: Env, path: String, arr: Array[Moon] ref) =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File do
        Iter[String](file.lines())
          .map_stateful[None]({(line)(arr) => arr.push(Moon.create(Utils.parse_coord(line)))})
          .run()
        file.dispose()
      end
    end

  fun apply_gravity_x(left: Moon, right: Moon) =>
    if left.pos_x > right.pos_x then
      left.velocity_x = left.velocity_x - 1
      right.velocity_x = right.velocity_x + 1
    elseif left.pos_x < right.pos_x then
      left.velocity_x = left.velocity_x + 1
      right.velocity_x = right.velocity_x - 1
    end

  fun apply_gravity_y(left: Moon, right: Moon) =>
    if left.pos_y > right.pos_y then
      left.velocity_y = left.velocity_y - 1
      right.velocity_y = right.velocity_y + 1
    elseif left.pos_y < right.pos_y then
      left.velocity_y = left.velocity_y + 1
      right.velocity_y = right.velocity_y - 1
    end

  fun apply_gravity_z(left: Moon, right: Moon) =>
    if left.pos_z > right.pos_z then
      left.velocity_z = left.velocity_z - 1
      right.velocity_z = right.velocity_z + 1
    elseif left.pos_z < right.pos_z then
      left.velocity_z = left.velocity_z + 1
      right.velocity_z = right.velocity_z - 1
    end

  fun step(arr: Array[Moon] ref) =>
    let size = arr.size()
    try
      var i: USize = 0
      while i < size do
        let moon_i = arr(i)?
        var j = i + 1
        while j < size do
          let moon_j = arr(j)?
          apply_gravity_x(moon_i, moon_j)
          apply_gravity_y(moon_i, moon_j)
          apply_gravity_z(moon_i, moon_j)
          j = j + 1
        end
        moon_i.step()
        i = i + 1
      end
    end

  fun energy(arr: Array[Moon] ref): U64 =>
    var total_energy: U64 = 0
    try
      var i: USize = 0
      while i < arr.size() do
        total_energy = total_energy + arr(i)?.energy()
        i = i + 1
      end
    end
    total_energy


actor Main
  new create(env: Env) =>
    let arr = Array[Moon].create(4)
    Utils.into_arr(env, "./12/input.txt", arr)
    for i in Range.create(0, 1001) do
      if (i.mod(10) == 0) then
        env.out.print("After ".add(i.string()).add(" steps:"))
        for moon in arr.values() do
          env.out.print(moon.string())
        end
        env.out.print(Utils.energy(arr).string())
      end
      Utils.step(arr)
    end
