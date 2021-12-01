#!/usr/bin/env escript

-mode(compile).

-export([main/1]).

main([FilePath]) ->
    G = digraph:new([cyclic]),
    {ok, Contents} = file:read_file(FilePath),
    Orbits = binary:split(Contents, [<<"\n">>], [global]),
    [begin
        [L, R] = binary:split(Orbit, [<<")">>], [global]),
        digraph:add_vertex(G, L),
        digraph:add_vertex(G, R),
        digraph:add_edge(G, L, R),
        digraph:add_edge(G, R, L)
    end || Orbit <- Orbits],
    [V1] = digraph:in_neighbours(G, <<"YOU">>),
    [V2] = digraph:in_neighbours(G, <<"SAN">>),
    Path = digraph:get_path(G, V1, V2),
    PathLen = lists:sum([1 || _ <- Path]) - 1,
    io:format("~p~n", [PathLen]).
