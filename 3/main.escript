#!/usr/bin/env escript

-mode(compile).

-export([main/1]).

span({X, FromY}, {X, ToY}) when FromY =< ToY ->
    [{X, N} || N <- lists:seq(FromY, ToY)];
span({X, FromY}, {X, ToY}) when FromY > ToY ->
    [{X, N} || N <- lists:seq(ToY, FromY)];
span({FromX, Y}, {ToX, Y}) when FromX =< ToX ->
    [{N, Y} || N <- lists:seq(FromX, ToX)];
span({FromX, Y}, {ToX, Y}) when FromX > ToX ->
    [{N, Y} || N <- lists:seq(ToX, FromX)].

create_path([], _, Acc) -> Acc;
create_path([Op | Rest], From = {SrcX, SrcY}, Acc) ->
    To = case Op of
	   {left, N} -> {SrcX - N, SrcY};
	   {right, N} -> {SrcX + N, SrcY};
	   {up, N} -> {SrcX, SrcY + N};
	   {down, N} -> {SrcX, SrcY - N}
	 end,
    NewAcc = lists:foldl(fun sets:add_element/2, Acc, span(From, To)),
    create_path(Rest, To, NewAcc).

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
    create_path(Ops, {0, 0}, sets:new()).

taxicab({FromX, FromY}, {ToX, ToY}) ->
    abs(FromX - ToX) + abs(FromY - ToY).

main([FilePath]) ->
    {ok, Contents} = file:read_file(FilePath),
    [Left, Right] = binary:split(Contents, [<<"\n">>], [global]),
    LeftPath = to_path(Left),
    RightPath = to_path(Right),
    [_Origin | CommonList] = sets:to_list(sets:intersection(LeftPath, RightPath)),
    Distances = [taxicab({0,0}, M) || M <- CommonList],
    io:format("Common: ~p~n", [Distances]),
    io:format("Min: ~p~n", [lists:min(Distances)]).

