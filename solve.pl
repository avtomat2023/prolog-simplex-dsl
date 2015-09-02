% Thanks to Ken-ichi Betsunou.

/*
LVC := [変数・定数項のリスト]
LEQ := [LVCのリスト]
*/
/*
% テスト %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
シンプレックス法のテスト その1
simplex(
  [[-2,-3, 0, 0, 0, 0 ],
   [ 1, 2, 1, 0, 0, 14],
   [ 1, 1, 0, 1, 0, 8 ],
   [ 3, 1, 0, 0, 1, 18]],
  Answer).
==>
Answer =

シンプレックス法のテスト その2
simplex(
[[-400,-300, 0, 0, 0,    0],
 [  60,  40, 1, 0, 0, 3800],
 [  20,  30, 0, 1, 0, 2100],
 [  20,  10, 0, 0, 1, 1200]],
Answer).

シンプレックス法のテスト その2
simplex(
  [[-1,-1,-1, 0, 0, 0, 0 ],
   [ 5, 1, 2, 1, 0, 0, 20],
   [ 2, 2, 6, 0, 1, 0, 30],
   [ 2, 6, 4, 0, 0, 1, 40]],
  Answer).
==>
Answer =
[[0.0, 0.0, 0.0, 0.13, 0.03, 0.13, 9.0],
 [1.0, 0.0, 0.0, 0.23,-0.06,-0.02, 2.0],
 [0.0, 0.0, 1.0,-0.07, 0.23,-0.07, 3.0],
 [0.0, 1.0, 0.0,-0.03,-0.13, 0.22, 4.0]].
% テスト %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

% シンプレックス法
% simplex(Simplex_tableau, Simplex_tableau_solved).
simplex([Z|St_rem], St_solved) :-
	finish(Z), % 最上行の係数が全て正になったので終了
	[Z|St_rem] = St_solved.
simplex([Z|St_rem], St_solved) :-
	not(finish(Z)), % 終了判定がfalse
	index_of_min(Q,Z), % 列選択を行う（Qを探す）
	select_row(P0,Q,St_rem), % 行選択を行う（Pを探す）
	P is P0 + 1,
	nth0(P,[Z|St_rem],Self), % ピボットのある行をSelfとする
	sweepout(0,P,Q,Self,[Z|St_rem],St_new), % 掃き出し法を行う
	simplex(St_new, St_solved).

% リストの最小値のインデックス (STEP1)
index_of_min(Idx,List) :-
	min_list(List,Min),
	nth0(Idx,List,Min).

% シンプレックス法の終了判断 （STEP2）
finish(List) :-
	min_list(List,Min),
	Min >= 0.

% 行選択を行う（STEP3）
select_row(P,Q,List_of_equations) :-
  % 各行について、Q列目の要素で右端の要素を割った値を求め、リストに格納させる
	select_row2(Q,List_of_equations,List_of_values),
  % リスト内の最小値のインデックスを求める（それが求める値P）
	index_of_positive_min(P,List_of_values).

% index_of_minのうち正の数に限定したもの
index_of_positive_min(Idx,List) :-
	positive_min_list(List,Min),
	nth0(Idx,List,Min).

% リストに含まれる数のうち最小の正整数を求める
positive_min_list([X],X) :-
	X > 0.
positive_min_list([H|T],Min) :-
	max_list([H|T],Max),
	hide_non_positive([H|T],NewList,Max), % 正でない数を隠ぺいする
	min_list(NewList,Min).

% 正でない数をMax+1に置き換えて隠ぺいする（positive_min_list用の補助述語）
hide_non_positive([],[],_).
hide_non_positive([H1|T1],[H2|T2],Max) :-
	not(H1 > 0),
	Max > 0,
	H2 is Max + 1,
	hide_non_positive(T1,T2,Max).
hide_non_positive([H1|T1],[H1|T2],Max) :-
	H1 > 0,
	Max > 0,
	hide_non_positive(T1,T2,Max).

select_row2(_,[],[]).
select_row2(Q,[H1|T1],[H2|T2]) :-
	select_row3(Q,H1,H2),
	select_row2(Q,T1,T2).

% ListのIdx番目の値で定数項（Lの最後の値）を割った値Valを求める
select_row3(Idx,List,Val) :-
	last(List,Last),
	nth0(Idx,List,Divisor),
	Val is Last / Divisor.

% 掃き出し演算（STEP4）
% sweepout(Row,P,Q,Self,LEQ,LEQ_after).
sweepout(_,_,_,_,[],[]).
sweepout(P,P,Q,Self,[Self|T1],[Normalized|T2]) :-
	Next is P + 1,
	nth0(Q,Self,Divisor),
	normalize(Divisor,Self,Normalized),
	sweepout(Next,P,Q,Self,T1,T2).
sweepout(Row,P,Q,Self,[H1|T1],[H2|T2]) :-
	Row \= P,
	haki2(Q,Self,H1,H2),
	Next is Row + 1,
	sweepout(Next,P,Q,Self,T1,T2).

% 全要素をXで割る
normalize(_,[],[]).
normalize(X,[H1|T1],[H2|T2]) :-
	H2 is H1 / X,
	normalize(X,T1,T2).

/*
sweepout テスト用
sweepout(0,1,1,[1,2,1,0,0,14],
[[-2,-3,0,0,0,0],
[1,2,1,0,0,14],
[1,1,0,1,0,8],
[3,1,0,0,1,18]], Output).
*/

% 各方程式について、掃き出しを行う際の係数を求める必要がある
keisuu(K,Q,Self,Target) :-
	nth0(Q,Self,Divisor),
	nth0(Q,Target,Divident),
	K is Divident / Divisor.

% 求めた係数、P行目の方程式、掃き出しを行う方程式のデータを利用して、掃き出しを行う←
haki(_,[],[],[]).
haki(K,[H1|T1],[H2|T2],[H3|T3]) :-
	H3 is H2 - K * H1,
	haki(K,T1,T2,T3).

% Q、元となる方程式、対象となる方程式を与えると、係数を求めて掃き出しを行う
haki2(Q,Self,Target,Target_after) :-
	keisuu(K,Q,Self,Target),
	haki(K,Self,Target,Target_after).

display_tableau([Z|Rest]) :-
    display_optimized_value(Z),
    display_variable_values([Z|Rest]).

/** display_optimized_value(FirstRow)
  *
  * Displays optimized value of objective function.
  *
  * @param FirstRow the first row of solved simplex tableau
  */
display_optimized_value(Row) :-
    display("Value of objective function: "),
    last(Row, Val),
    display(Val), nl.

/** display_variable_values(Tableau)
  *
  * Finds basis variables and display their values.
  *
  * @param Tableau the solved simplex tableau
  */
display_variable_values(SubTableau) :-
    SubTableau = [HeadRow|_],
    length(HeadRow, Len),
    Len > 1,
    col_and_rest(SubTableau, Col, Rest),
    find_unique_one_index(Col, Index),
    Index > 0,
    nth0(Index, SubTableau, Row),
    last(Row, Value),
    NVar is Index - 1,
    display("$"), display(NVar), display(" = "), display(Value), nl,
    display_variable_values(Rest).

/** col_and_rest(Table, Col, Rest)
  *
  * Decomposes a 2-dimentional array into the first column and
  * the rest of the array without the column.
  *
  * @param Table the 2-dimentional array represented by a list of lists with the
  *              same number of elements
  * @param Col the first column
  * @param Rest the rest of the array
  *
  * Example:
  *   ?- col_and_rest([[0,1,2],[3,4,5],[6,7,8],[9,10,11]], Col, Rest).
  *   Col = [0, 3, 6, 9],
  *   Rest = [[1, 2], [4, 5], [7, 8], [10, 11]].
  */
col_and_rest([], [], []).
col_and_rest([[Hd|Tl]|Rows], Col, Rest) :-
    col_and_rest(Rows, ColTl, RestTl),
    Col = [Hd|ColTl],
    Rest = [Tl|RestTl].

/** find_unique_one_index(List, Index)
  *
  * If the list contains only one element almost 1.0 and
  * all others are almost 0.0, returns the index of 1.0 element.
  *
  * @param List the list of numbers (int or float)
  * @param Index the index of 1.0 element
  *
  * Example:
  *   ?- find_unique_one_index([0,0,1,0], Index).
  *   Index = 2.
  *   ?- find_unique_one_index([0,1,0,1], Index).
  *   false.
  */
find_unique_one_index([], _) :- fail.
find_unique_one_index([Hd|Tl], Index) :-
    almost_equal(Hd, 1.0), !,
    list_forall(almost_zero, Tl),
    Index is 0.
find_unique_one_index([_|Tl], Index) :-
    find_unique_one_index(Tl, TlIndex),
    Index is TlIndex + 1.

/** almost_equal(X, Y)
  *
  * Successes iff X and Y are almost same number.
  */
almost_equal(X, Y) :-
    Epsilon is 1.0e-8,
    -Epsilon < X - Y,
    X - Y < Epsilon.

almost_zero(X) :- almost_equal(X, 0.0).

/** list_forall(Pred, List)
  *
  * Successes iff for all element `Elt` of the list, `call(Pred, Elt)`
  * successes.
  */
list_forall(_, []) :- !.
list_forall(Pred, [Hd|Tl]) :-
    call(Pred, Hd),
    list_forall(Pred, Tl).
