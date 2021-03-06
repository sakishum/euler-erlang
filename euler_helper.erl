-module(euler_helper).
-include_lib("eunit/include/eunit.hrl").
-export([prime/1,dividable_by/2,gcd/2,lcm/2,lcm_multiple/1, int_to_digit_list/1, int_pow/2, int_pow_fun/3, fac/1, triangle_seq/1, dijkstra/2, longest_path/2, read_triangular_graph_data/1, divisors/1, sdivisors/1, fib/1]).

-define(LONG_TEST_PRIME, 1073807359).
-define(infinity,9999999999999999999999999).


prime(X) when X < 2 ->
    false;
prime(X) ->
    prime(1,X).

prime(_,1) -> false;
prime(1,X) -> prime(2,X);
prime(Y,X) ->
    NeedsTest = needs_prime_testing(Y,X),
    if
        NeedsTest ->
            not (dividable_by(X,Y)) andalso prime(Y+1,X);
        true ->
            true
    end.

dividable_by(N,K) ->
    N rem K =:= 0.

needs_prime_testing(Y,X) ->
    Y =< math:sqrt(X).

%% euclids algorithm
gcd(X,0) ->
    X;
gcd(X,Y) ->
    gcd(Y,X rem Y).

lcm(X,Y) ->
    (X * Y) div gcd(X,Y).

lcm_multiple([X,Y|[]]) ->
    lcm(X,Y);
lcm_multiple([X,Y|T]) ->
    lcm_multiple([lcm(X,Y)|T]).

int_to_digit_list(N) ->
    lists:map(fun(X) -> {K,_} = string:to_integer([X]), K end, integer_to_list(N)).

int_pow(0,_) ->
    0;
int_pow(_,0) ->
    1;
int_pow(B,E) ->
    int_pow(0,B,E).

int_pow(K,B,E) ->
    int_pow_fun(K,B,E,fun(X) -> X end).

int_pow_fun(B,E,F) ->
    int_pow_fun(0,B,E,F).

int_pow_fun(K,B,E,F) ->
    if
        K >= E ->
            F(1);
        true ->
            F(B * int_pow_fun(K+1,B,E,F))
    end.

fac(0) ->
    1;
fac(N) ->
    fac(1,N).

fac(K,N) ->
    if
        K  >= N + 1 ->
            1;
        true ->
            K * fac(K+1,N)
    end.

triangle_seq(N) when N > 0 ->
    lists:sum(lists:seq(1,N)).

longest_path(G,Start) ->
    Dist = orddict:from_list([ {X,0} || X <- digraph:vertices(G)]),
    {_, StartVal} = digraph:vertex(G,Start),
    NewDist = orddict:store(Start,StartVal,Dist),
    FinalDist = longest_path_vertex_it(G,digraph_utils:topsort(G),NewDist),
    {_,MaxDist} = orddict:fold(fun (Key,Val,{MaxNode,MaxVal}) -> if Val > MaxVal -> {Key,Val}; true -> {MaxNode,MaxVal} end end, {error, 0}, FinalDist),
    MaxDist.

longest_path_vertex_it(_,[],FinalDist) ->
    FinalDist;
longest_path_vertex_it(G,[H|T],Dist) ->
    UpdatedDist = longest_path_edge_it(G,H,digraph:out_neighbours(G,H),Dist),
    longest_path_vertex_it(G,T,UpdatedDist).

longest_path_edge_it(_,_,[],ItFinalDist) ->
    ItFinalDist;
longest_path_edge_it(G,V,[W|T],Dist) ->
    {_,NodeDist} = digraph:vertex(G,W),
    VLength = orddict:fetch(V,Dist),
    WLength = orddict:fetch(W,Dist),
    NewDist = if
                  WLength =< VLength + NodeDist ->
                      orddict:store(W,VLength + NodeDist,Dist);
                  true ->
                      Dist
              end,
    longest_path_edge_it(G,V,T,NewDist).


dijkstra(G,Source) ->
    Dist = orddict:from_list([{X,?infinity} || X <- digraph:vertices(G)]),
    Prev = orddict:new(),
    {_,FirstVal} = digraph:vertex(G,Source),
    NewDist = orddict:store(Source,FirstVal,Dist),
    Q = sets:from_list(digraph:vertices(G)),
    dijkstra_it(G,Source,Prev,NewDist,Q).

dijkstra_it(G,Source,Prev,Dist,Q) ->
    Empty = sets:size(Q) == 0,
    if
        Empty ->
            {Prev,Dist};
        true -> 
            {MaxNode,_} = orddict:fold(
                                  fun (Key, Val, {MaxNode, Max}) ->
                                          InQ = sets:is_element(Key,Q),
                                          if
                                              InQ andalso (Val > Max) ->
                                                  {Key, Val};
                                              true -> {MaxNode,Max}
                                          end
                                  end,
                                  {false,-2}, Dist),
            SmallerQ = sets:del_element(MaxNode,Q),
            Neighbors = lists:filter(fun (X) -> sets:is_element(X,Q) end, digraph:out_neighbours(G,MaxNode)),
            {UpdatedDist, UpdatedPrev} = update_distances(G,MaxNode,Neighbors,Dist,Prev),
            dijkstra_it(G,Source,UpdatedPrev,UpdatedDist,SmallerQ)
    end.

update_distances(_,_,[],Dist,Prev) ->
    {Dist,Prev};
update_distances(G,MaxNode,[H|T],Dist,Prev) ->
    {_,K} = digraph:vertex(G,H),
    NewDist = orddict:fetch(MaxNode,Dist) + K,
    OldDist = orddict:fetch(H,Dist),
    UpdatedDist = if NewDist > OldDist -> orddict:store(H,NewDist,Dist); true -> Dist end,
    UpdatedPrev = if NewDist > OldDist -> orddict:store(H,MaxNode,Prev); true -> Prev end,
    update_distances(G,MaxNode,T,UpdatedDist,UpdatedPrev).

read_triangular_graph_data(File) ->
    {ok,[NList]} = file:consult(File),
    create_triangle_graph(NList).

create_triangle_graph(NList) ->
    PList = partition_triangular_list(NList),
    G = digraph:new([acyclic]),
    add_triangle_graph_vertices(G,lists:flatten(PList)),
    add_triangle_graph_edges(G,PList),
    G.
    
add_triangle_graph_vertices(G,[]) ->
    {ok,G};
add_triangle_graph_vertices(G,[{Label,Num}|Rest]) ->
    digraph:add_vertex(G,Num,Label),
    add_triangle_graph_vertices(G,Rest).

add_triangle_graph_edges(_,[_|[]]) ->
    [];
add_triangle_graph_edges(G,[H1,H2|T]) ->
    [digraph:add_edge(G,P1,P2) || {_,P1} <- H1, {_,P2} <- H2, triag_offset_in_row(P1) == triag_offset_in_row(P2) orelse triag_offset_in_row(P1) + 1  == triag_offset_in_row(P2)],
    add_triangle_graph_edges(G,[H2|T]).

partition_triangular_list(L) ->
    partition_triangular_lists(1,L).

partition_triangular_lists(_,[]) ->
    [];
partition_triangular_lists(K,L) ->
    {RetList,RestList} = lists:split(K,L),
    F = fun(X,[{Y,N}|Rest]) -> [{X,N+1},{Y,N}|Rest];
           (X,Rest) -> [{X,triag_row_to_offset(K)}|Rest]
        end,
    [lists:reverse(lists:foldl(F,[],RetList))] ++ partition_triangular_lists(K+1,RestList).

triag_row_to_offset(1) ->
    1;
triag_row_to_offset(N) ->
    N - 1 + triag_row_to_offset(N-1).

triag_offset_in_row(N) ->
    triag_offset_in_row(1,N).

triag_offset_in_row(K,N) ->
    NextOffset = triag_row_to_offset(K + 1),
    if
        NextOffset > N ->
            N - triag_row_to_offset(K);
        true ->
            triag_offset_in_row(K+1,N)
    end.

divisors(0) ->
    [];
divisors(1) ->
    [];
divisors(N) ->
    lists:sort(divisors(1,N)).

divisors(1,N) ->
    [1] ++ divisors(2,N);
divisors(K,N) ->
    Enough = K > math:sqrt(N),
    if
        Enough ->
            [];
        true ->
            if
                N rem K == 0 ->
                    if K * K == N ->
                            [K];
                       true ->
                            [K, N div K]
                    end;
                true ->
                    []
            end ++ divisors(K+1,N)
    end.

sdivisors(N) ->
    lists:sum(divisors(N)).

fib(1) ->
    1;
fib(2) ->
    2;
fib(N) ->
    fib(N-2) + fib(N-1).


%% tests

fib_one_test() ->
    ?assertEqual(1,fib(1)).

fib_two_test() ->
    ?assertEqual(2,fib(2)).

fib_six_test() ->
    ?assertEqual(13,fib(6)).

triangle_seq_test_() ->
    [?_assertEqual(1,triangle_seq(1)),
     ?_assertEqual(28,triangle_seq(7)),
     ?_assertError(function_clause,triangle_seq(0)),
     ?_assertError(function_clause,triangle_seq(-4))].

prime_test_() ->
    [ ?_assert(prime(2)),
      ?_assert(prime(3)),
      ?_assert(prime(5)),
      ?_assert(prime(7)),
      ?_assertNot(prime(1)),
      ?_assertNot(prime(4)),
      ?_assertNot(prime(6)),
      ?_assertNot(prime(9)) ].

prime_long_test() ->
    ?assert(prime(?LONG_TEST_PRIME)).

prime_long_neg_test() ->
    ?assertNot(prime(?LONG_TEST_PRIME+1)).

prime_it_test() ->
    ?assert(prime(1,7)).

prime_it_not_test() ->
    ?assertNot(prime(1,4)).

dividable_by_test() ->
    ?assert(dividable_by(12,3)).

dividable_by_not_test() ->
    ?assertNot(dividable_by(12,5)).

needs_prime_testing_test_() ->
    [ ?_assert(needs_prime_testing(2,9)),
      ?_assertNot(needs_prime_testing(7,42)) ].

gcd_test_() ->
    [ ?_assertEqual(gcd(1,0),1),
      ?_assertEqual(gcd(4,8),4),
      ?_assertEqual(gcd(54,24),6)].

lcm_test_() ->
    [ ?_assertEqual(lcm(21,6),42),
      ?_assertEqual(lcm(3,4),12) ].

lcm_multiple_test_() ->
    [ ?_assertEqual(lcm_multiple([21,6]),42),
      ?_assertEqual(lcm_multiple(lists:seq(1,10)),2520)].

int_to_digit_list_test_() ->
    [ ?_assertEqual([1,2],int_to_digit_list(12)),
      ?_assertEqual([1,4,5],int_to_digit_list(145)) ].

int_pow_test_() ->
    [ ?_assertEqual(1,int_pow(2,0)),
     ?_assertEqual(9,int_pow(3,2))].

int_pow_fun_test_() ->
    [ ?_assertEqual(0,int_pow_fun(32,2,fun(_) -> 0 end)) ].

fac_test_() ->
    [ ?_assertEqual(1,fac(0)),
      ?_assertEqual(1,fac(1)),
      ?_assertEqual(40320,fac(8))].


partition_list_test_() ->
    [
     ?_assertEqual([[{4,1}]],partition_triangular_list([4])),
     ?_assertEqual([[{11,1}],[{22,2},{33,3}]],partition_triangular_list([11,22,33])),
     ?_assertEqual([[{11,1}],[{22,2},{33,3}],[{44,4},{55,5},{66,6}]],partition_triangular_list([11,22,33,44,55,66]))
    ].

triag_row_to_offset_test_() ->
    [
     ?_assertEqual(1,triag_row_to_offset(1)),
     ?_assertEqual(2,triag_row_to_offset(2)),
     ?_assertEqual(4,triag_row_to_offset(3)),
     ?_assertEqual(7,triag_row_to_offset(4)),
     ?_assertEqual(11,triag_row_to_offset(5)),
     ?_assertEqual(16,triag_row_to_offset(6)),
     ?_assertEqual(22,triag_row_to_offset(7))
    ].

triag_offset_in_row_test_() ->
    [
     ?_assertEqual(0,triag_offset_in_row(1)),
     ?_assertEqual(1,triag_offset_in_row(8)),
     ?_assertEqual(3,triag_offset_in_row(10))
    ].


divisors_test_() ->
    [
     ?_assertEqual([],divisors(0)),
     ?_assertEqual([],divisors(1)),
     ?_assertEqual([1],divisors(2)),
     ?_assertEqual([1,2,3],divisors(6)),
     ?_assertEqual([1,2,3,4,6],divisors(12))
    ].
