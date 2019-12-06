#!/usr/bin/env escript

-mode(compile).

-export([main/1]).

main([FilePath]) ->
    G = digraph:new([acyclic]),
    {ok, Contents} = file:read_file(FilePath),
    Orbits = binary:split(Contents, [<<"\n">>], [global]),
    [begin
        [L, R] = binary:split(Orbit, [<<")">>], [global]),
        digraph:add_vertex(G, L),
        digraph:add_vertex(G, R),
        digraph:add_edge(G, L, R)
    end || Orbit <- Orbits],
    TotalOrbits = lists:sum(
        [lists:sum([1 || _ <- digraph_utils:reaching([V, <<"COM">>], G)]) - 1
            || V <- digraph_utils:topsort(G)]
    ),
    io:format("~b~n", [TotalOrbits]).
