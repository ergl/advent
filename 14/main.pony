use "files"
use "collections"

type ChemAmount is (U64, String)
type Formula is Array[ChemAmount]
type Reaction is (U64, Formula)
type CookBook is HashMap[String, Reaction, StringHash]
type Remainders is HashMap[String, U64, StringHash]

class val StringHash is HashFunction[String]
  fun hash(s: String): USize => s.hash()
  fun eq(left: String, right: String): Bool => left == right

primitive ParseUtils
  fun _parse_ingredient(str: String iso): ChemAmount? =>
    let parts = str.>strip().split_by(" ")
    let amount = parts(0)?
    let element_name = parts(1)?
    (amount.u64()?, element_name)

  fun _parse_formula(out: OutStream, str: String iso): Formula iso^? =>
    let arr = recover Array[(U64, String)] end
    for ingr in str.>strip().split_by(",").values() do
      arr.push(_parse_ingredient(ingr.clone())?)
    end
    arr

  fun _parse_recipe(out: OutStream, str: String iso, cookbook: CookBook ref) =>
    let parts = str.split_by("=>")
    try
      (let amount, let name) = _parse_ingredient(parts(1)?.clone())?
      let formula = _parse_formula(out, parts(0)?.clone())?
      cookbook.insert(name, (amount, consume formula))
    end

  fun parse_file(env: Env, path: String, cookbook: CookBook ref) =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File do
      for line in file.lines() do
        _parse_recipe(env.out, consume line, cookbook)
      end
      end
    end

actor Main
  fun get_from_cache(element: String, need: U64, remainders: Remainders ref): U64 =>
    let cached = remainders.get_or_else(element, 0)
    if cached < need then
      // There are less remaining elements than needed, so just empty the cache,
      // and return the difference
      try remainders.remove(element)? end
      need - cached
    else
      // There are more remaining elements than needed, so just take as many as needed,
      // and return 0, as we don't need to process this element
      remainders(element) = cached - need
      0
    end

  fun walk_branch(element: String, need: U64, cookbook: CookBook box, remainders: Remainders ref): U64 =>
    let really_needs = get_from_cache(element, need, remainders)
    if (really_needs == 0) or (element == "ORE") then
      return really_needs
    end

    var total: U64 = 0
    try
      (let elements_produced, let formula) = cookbook(element)?
      (let quot, let rem) = really_needs.divrem(elements_produced)
      (let child_needs, let remains) = if rem == 0 then (quot, 0) else (quot + 1, elements_produced - rem) end
      remainders.upsert(element, remains, {(current, provided) => current + provided })
      for child in formula.values() do
        (let child_mult, let child_element) = child
        total = total + walk_branch(child_element, child_needs * child_mult, cookbook, remainders)
      end
    end
    total

  new create(env: Env) =>
    let book = CookBook
    ParseUtils.parse_file(env, "./14/input.txt", book)
    let total_ore = walk_branch("FUEL", 1, book, Remainders)
    env.out.print("Need ".add(total_ore.string()).add(" pieces of ore"))
