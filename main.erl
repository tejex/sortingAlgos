-module(main).
-import(io,[fwrite/1]).
-export([
         start/0,
         selSort/1,
         mergeSort/1,
         parallelMergeSort/1,
         parallelMergeFour/1,
         parallelMergeEight/1,
         parallelSelSort/1,
         parallelSelSortFour/1,
         parallelSelSortEight/1,
         run_mergeSort/0,
         run_split/0,
         run_selSort/0,
         create_list/2
  ]).

start() ->
      seed(),
    List = create_list( 1000000, 10000 ),
    { Time1, _ } = timer:tc( main, mergeSort, [List] ),
    io:format( "Straight Merge sort took: ~p seconds.~n", [Time1 / 1000000] ),
    { Time2, _ } = timer:tc( main, parallelMergeSort , [List] ),
    io:format( "Merge sort with two processes sort took: ~p seconds.~n", [Time2 / 1000000]),
    { Time3, _ } = timer:tc( main, parallelMergeFour , [List] ),
    io:format( "Merge sort with four processes took: ~p seconds.~n", [Time3 / 1000000] ),
    { Time4, _ } = timer:tc( main, parallelMergeEight , [List] ),
    io:format( "Merge sort with Eight processes took: ~p seconds.~n", [Time4 / 1000000] ),
    { Time5, _ } = timer:tc( lists, sort, [List] ),
    io:format( "Built in sort took ~p seconds.~n", [Time5 / 1000000] ),
    io:format( "Thanks!~n" ).

seed( ) ->
    rand:seed( exsss, { erlang:phash2( node( ) ), erlang:monotonic_time( ), erlang:unique_integer( ) } ).

create_list( 0, _ ) -> [];

create_list( Length, Max ) ->
    [ rand:uniform( Max ) | create_list( Length - 1, Max ) ].

% Implement One fast sorting algorithm and on slow sorting algorithm 

%% Slow Algorithm: Selection Sort
%% Fast Algorithm: Merge Sort

%% We need 4 different versions of both of these kinds of sorting algorithms

%------------------------------ Selection Sort -------------------------%
findSmallest([X]) -> X;

findSmallest([H | T]) ->
  C = findSmallest(T),
  if
    H < C -> H;
    true -> C
  end.
%---------------------------------------------------------------------------------%
remove( _ ,[]) -> [];

remove(H, [H | T]) -> T;

remove(X, [H | T]) ->
  [H | remove(X, T)].
%---------------------------------------------------------------------------------%
selSort([]) -> [];

selSort([X]) -> [X];

selSort(List) ->
  S = findSmallest(List),
  R = remove(S, List),
  [S | selSort(R)].
  
%----------------------  Merge Sort ----------------------%
mergeSort([]) -> [];

mergeSort([X]) -> [X];

mergeSort(List) ->
  {Left,Right} = split(List), merge(mergeSort(Left), mergeSort(Right)).
%---------------------------------------------------------------------------------%         
split( List ) ->
    split_help( length(List) div 2, List, [] ).

split_help( 0, Original, Front ) ->
    { Front, Original };

split_help( N, [H|T], Front ) ->
    split_help( N - 1, T, [H | Front] ).

%---------------------------------------------------------------------------------%
merge([],List2) -> List2;

merge(List1, []) -> List1;

merge([H1 | T1] , [H2 | T2]) ->
  if H1 < H2 ->
      [H1 | merge(T1, [H2 | T2])];
    true -> 
      [H2 | merge([H1 | T1], T2)]
  end.

%-------------------------Starting Parallel Merge Sort----------------------%
run_mergeSort() ->
    receive
      { Pid, List } -> 
          Sorted = mergeSort( List ),
          Pid ! Sorted;
      _ -> io:format( "Error!" )
  end.

run_merge() ->
  receive
    {Pid, ListA, ListB} ->
      Merged = merge(ListA, ListB),
      Pid ! Merged;
    _ ->io:format("Error!")
  end.

run_split() ->
  receive
    {Pid, List} ->
      {Front, Back} = split(List),
      Pid ! {Front, Back};
    _ ->io:format( "Error!" )
  end.
%------------------------Merge sort with two processes----------------------%
parallelMergeSort(List) ->
  {Front, Back} = split(List),
  PidA = spawn(main,run_mergeSort,[]),
  PidB = spawn(main,run_mergeSort,[]),
  PidA ! {self(), Front},
  PidB ! {self(), Back},
  receive
    X -> SortedA = X
  end,
  receive
    Y -> SortedB = Y
  end,
  merge(SortedA, SortedB).
%------------------------Merge sort with Four processes----------------------%
parallelMergeFour(List) ->
  {Front, Back} = split(List),
  
  {FrontA, BackA} = split(Front),
  {FrontB, BackB} = split(Back),

  PidA = spawn(main,run_mergeSort,[]),
  PidA2 = spawn(main,run_mergeSort,[]),
  PidB = spawn(main,run_mergeSort,[]),
  PidB2 = spawn(main,run_mergeSort,[]),

  PidA ! {self(), FrontA},
  PidA2 ! {self(), BackA},
  PidB ! {self(), FrontB},
  PidB2 ! {self(), BackB},

  receive
    A -> SortedA = A
  end,
  receive
    A2 -> SortedA2 = A2
  end,
  
  receive
    B -> SortedB = B
  end,
  receive
    B2 -> SortedB2 = B2
  end,
  
  PartA = merge(SortedA, SortedA2),
  PartB = merge(SortedB, SortedB2),
  merge(PartA,PartB).
%------------------------Merge sort with Eight processes----------------------%
parallelMergeEight(List) ->
  {Front, Back} = split(List),
  {FrontA, BackA} = split(Front),                      
  {FrontB, BackB} = split(Back),
                    

  {FrontA1, BackA1} = split(FrontA),
  {FrontA2, BackA2} = split(BackA),   
  {FrontB1, BackB1} = split(FrontB),
  {FrontB2, BackB2} = split(BackB), 
                      
                           
  PidA = spawn(main,run_mergeSort,[]),
  PidB = spawn(main,run_mergeSort,[]),

  PidC = spawn(main,run_mergeSort,[]),
  PidD = spawn(main,run_mergeSort,[]),

  PidE = spawn(main,run_mergeSort,[]),
  PidF = spawn(main,run_mergeSort,[]),

  PidG = spawn(main,run_mergeSort,[]),
  PidH = spawn(main,run_mergeSort,[]),   
                      
  
  PidA ! {self(), FrontA1},
  PidB ! {self(), BackA1},
  PidC ! {self(), FrontA2},
  PidD ! {self(), BackA2},     

  PidE ! {self(), FrontB1},
  PidF ! {self(), BackB1},
  PidG ! {self(), FrontB2},
  PidH ! {self(), BackB2},                         

  receive
    A -> SortedFrontA1 = A
  end,
  receive
    B -> SortedBackA1 = B
  end,
  
  receive
    C -> SortedFrontA2 = C
  end,
  receive
    D -> SortedBackA2 = D
  end,
                      
  receive
    E -> SortedFrontB1 = E
  end,
  receive
    F -> SortedBackB1 = F
  end,
  
  receive
    G -> SortedFrontB2 = G
  end,
  receive
    H -> SortedBackB2 = H
  end,
                      
  AB = merge(SortedFrontA1,SortedBackA1),
  CD = merge(SortedFrontA2,SortedBackA2 ),
  EF = merge(SortedFrontB1,SortedBackB1),
  GH = merge(SortedFrontB2, SortedBackB2),

  ABCD = merge(AB, CD),
  EFGH = merge(EF, GH),
  merge(ABCD, EFGH).
                      
%---------------------------------------------------------------------------------%
run_selSort() ->
  receive
    {Pid, List} ->
      Sorted = selSort(List),
      Pid ! Sorted;
    _ -> io:format("Error")
  end.
%-----------------------------------Selection Sort Two----------------------------------%
parallelSelSort(List) ->
  {Front, Back} = split(List),
  Pid1 = spawn(main,run_selSort,[]),
  Pid2 = spawn(main,run_selSort,[]),

  Pid1 ! {self(), Front},
  Pid2 ! {self(), Back},

  receive
    A -> SortedA = A
  end,
  receive
    B -> SortedB = B
  end,
  merge(SortedA, SortedB).
%----------------------------------Selection Sort Four --------------------------------%
parallelSelSortFour(List) ->
  {Front, Back} = split(List),

  {FrontA,BackA} = split(Front),
  {FrontB,BackB} = split(Back),

  Pid1 = spawn(main,run_selSort,[]),
  Pid2 = spawn(main,run_selSort,[]),
  Pid3 = spawn(main,run_selSort,[]),
  Pid4 = spawn(main,run_selSort,[]),

  
  Pid1 ! {self(), FrontA},
  Pid2 ! {self(), BackA},
  Pid3 ! {self(), FrontB},
  Pid4 ! {self(), BackB},

  receive
    A -> SortedA = A
  end,
  receive
    B -> SortedB = B
  end,
  receive
    C -> SortedC = C
  end,
  receive
    D -> SortedD = D
  end,
  
  AB = merge(SortedA,SortedB),
  CD = merge(SortedC,SortedD),
  merge(AB,CD).
%----------------------------------Selection Sort Eight --------------------------------%
parallelSelSortEight(List) ->
  {Front, Back} = split(List),
  {FrontA, BackA} = split(Front),                      
  {FrontB, BackB} = split(Back),
                    

  {FrontA1, BackA1} = split(FrontA),
  {FrontA2, BackA2} = split(BackA),   
  {FrontB1, BackB1} = split(FrontB),
  {FrontB2, BackB2} = split(BackB), 
                      
                           
  PidA = spawn(main,run_selSort,[]),
  PidB = spawn(main,run_selSort,[]),

  PidC = spawn(main,run_selSort,[]),
  PidD = spawn(main,run_selSort,[]),

  PidE = spawn(main,run_selSort,[]),
  PidF = spawn(main,run_selSort,[]),

  PidG = spawn(main,run_selSort,[]),
  PidH = spawn(main,run_selSort,[]),   
                      
  
  PidA ! {self(), FrontA1},
  PidB ! {self(), BackA1},
  PidC ! {self(), FrontA2},
  PidD ! {self(), BackA2},     

  PidE ! {self(), FrontB1},
  PidF ! {self(), BackB1},
  PidG ! {self(), FrontB2},
  PidH ! {self(), BackB2},                         

  receive
    A -> SortedFrontA1 = A
  end,
  receive
    B -> SortedBackA1 = B
  end,
  
  receive
    C -> SortedFrontA2 = C
  end,
  receive
    D -> SortedBackA2 = D
  end,
                      
  receive
    E -> SortedFrontB1 = E
  end,
  receive
    F -> SortedBackB1 = F
  end,
  
  receive
    G -> SortedFrontB2 = G
  end,
  receive
    H -> SortedBackB2 = H
  end,
                      
  AB = merge(SortedFrontA1,SortedBackA1),
  CD = merge(SortedFrontA2,SortedBackA2 ),
  EF = merge(SortedFrontB1,SortedBackB1),
  GH = merge(SortedFrontB2, SortedBackB2),

  ABCD = merge(AB, CD),
  EFGH = merge(EF, GH),
  merge(ABCD, EFGH).
%--------------------------------------------------------------------------------------%