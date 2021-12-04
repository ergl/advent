use "files"

actor Main
  var path: String = "./input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        (let balls, let boards) = ParseFile(file.lines())
        silver(env.out, balls, boards)
      end
    else
      env.err.print("Error")
    end

  fun tag silver(
    out: OutStream,
    balls: Array[U32] box,
    boards: Array[Board] ref)
  =>
    var winner_board: (USize | None) = None
    var winner_sum: U64 = 0
    var winner_ball: U32 = 0

    for ball in balls.values() do
      if winner_board isnt None then
        break
      end
      for board in boards.values() do
        board.mark_ball(ball)
      end
      for (idx, board) in boards.pairs() do
        if board.is_bingo() then
          winner_ball = ball
          winner_board = idx
          winner_sum = board.sum_unmarked()
          break
        end
      end
    end

    match winner_board
    | None =>
      out.print("Error: no winners!")
    | let b: USize =>
      out.print(
        "Winner is board " + b.string() + " after drawing ball " +
        winner_ball.string() + " for a total score of " + winner_sum.string() + 
        ".\nThe final answer is " + (winner_ball.u64() * winner_sum).string()
      )
    end
