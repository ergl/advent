#!/usr/bin/env escript

-mode(compile).

-export([main/1]).

span(Src={X, FromY}, {X, ToY}, ExtraSteps) when FromY =< ToY ->
    [{{X, N}, ExtraSteps + taxicab(Src, {X, N})} || N <- lists:seq(FromY, ToY)];

span(Src={X, FromY}, {X, ToY}, ExtraSteps) when FromY > ToY ->
    [{{X, N}, ExtraSteps + taxicab(Src, {X, N})} || N <- lists:seq(ToY, FromY)];

span(Src={FromX, Y}, {ToX, Y}, ExtraSteps) when FromX =< ToX ->
    [{{N, Y}, ExtraSteps + taxicab(Src, {N, Y})} || N <- lists:seq(FromX, ToX)];

span(Src={FromX, Y}, {ToX, Y}, ExtraSteps) when FromX > ToX ->
    [{{N, Y}, ExtraSteps + taxicab(Src, {N, Y})} || N <- lists:seq(ToX, FromX)].

create_path(Ops, From) ->
    create_path(Ops, From, 0, sets:new(), #{}).

create_path([], _, _, AccPoints, AccSteps) -> {AccPoints, AccSteps};
create_path([Op | Rest], From = {SrcX, SrcY}, PrevCost, AccPoints, AccSteps) ->
    To = case Op of
        {left, N} -> {SrcX - N, SrcY};
        {right, N} -> {SrcX + N, SrcY};
        {up, N} -> {SrcX, SrcY + N};
        {down, N} -> {SrcX, SrcY - N}
    end,

    Span = span(From, To, PrevCost),
    {NewCost, NewPoints, NewMap} = lists:foldl(fun({Point, Steps}, {Acc1, Acc2, Acc3}) ->
        {erlang:max(Steps, Acc1), sets:add_element(Point, Acc2), Acc3#{Point => Steps}}
    end, {PrevCost, AccPoints, AccSteps}, Span),

    create_path(Rest, To, NewCost, NewPoints, NewMap).

to_path(String) ->
    Ops = lists:map(fun (<<P:8, Rest/binary>>) ->
        Op = case P of
            82 -> right;
            76 -> left;
            85 -> up;
            68 -> down
        end,
        {Op, binary_to_integer(Rest)}
    end, binary:split(String, [<<",">>], [global])),
    create_path(Ops, {0, 0}).

taxicab({FromX, FromY}, {ToX, ToY}) ->
    abs(FromX - ToX) + abs(FromY - ToY).

main([FilePath]) ->
    {ok, Contents} = file:read_file(FilePath),
    [Left, Right] = binary:split(Contents, [<<"\n">>], [global]),
    {LeftPath, LeftCosts} = to_path(Left),
    {RightPath, RightCosts} = to_path(Right),
    [_Origin | CommonList] = sets:to_list(sets:intersection(LeftPath, RightPath)),
    IntersectionCosts = lists:map(fun(Point) ->
        maps:get(Point, LeftCosts) + maps:get(Point, RightCosts)
    end, CommonList),
    io:format("Min cost: ~p~n", [lists:min(IntersectionCosts)]).
