/** Operator '$' for expressions.
  * For integer n (>= 0) and float k, '$n' means nth variable and
  * 'k$n' does k * (nth variable). This kind of terms can be added by infix '+'
  * operator.
  *
  * Example:
  *   $0                     ... x[0]
  *   3$0 + $1 + 1.5$2       ... 3*x[0] + x[1] + 1.5*x[2]
  *   $0 + $3 + $0 + $2 + $1 ... x[0] + x[3] + x[0] + x[2] + x[1]
  *
  * All expressions are generated by the following grammar:
  * EXPR ::= $n
  *        | k$n
  *        | EXPR + EXPR
  */
:- op(300, fx, $).
:- op(400, xfx, $).

/** expr_to_vector(Expr, List)
  *
  */
expr_to_vector($N, Row) :-
    expr_to_vector(1.0$N, Row).

expr_to_vector(Coeff$N, Row) :-
    zeros(N, List),
    append(List, [Coeff], Row).

expr_to_vector(Lhs+Rhs, Row) :-
    expr_to_vector(Lhs, LRow),
    expr_to_vector(Rhs, RRow),
    vector_add(LRow, RRow, Row).

vector_add([], Row2, Row2) :- !.
vector_add(Row1, [], Row1) :- !.
vector_add([Hd1|Tl1], [Hd2|Tl2], Row) :-
    HdSum is Hd1 + Hd2,
    vector_add(Tl1, Tl2, TlSum),
    Row = [HdSum | TlSum].

zeros(0, []) :- !.
zeros(N, List) :-
    N > 0,
    NextN is N - 1,
    zeros(NextN, Tl),
    List = [0.0 | Tl].

/* test:
 * expr_to_vector($1 + 1$0 + $1 + 3$2, Row).
 */

/** Inequality operator for registration of constraints.
  * Left hand sides are expressions and right hand sides are floats.
  *
  * Example:
  *   $0 + $2 + $0 <= 1.2 ... register constraint: x[0] + x[2] + x[0] <= 1.2
  */
:- op(700, xfx, :<=).
Expr :<= Const :-
    expr_to_vector(Expr, Row),
    assert(constraint(le, Row, Const)).

:- op(700, xfx, :>=).
Expr :>= Const :-
    expr_to_vector(Expr, Row),
    assert(constraint(ge, Row, Const)).

:- op(700, xfx, :==).
Expr :== Const :-
    expr_to_vector(Expr, Row),
    assert(constraint(eq, Row, Const)).

/** Maximize indicator. Left hand sides are expressions as objective functions
  * and right hand sides are nullary atoms 'max'.
  *
  * Example:
  *   $0 + 2$1 + 0.5$2 => max ... maximize: x[0] + 2*x[1] + 0.5*x[2]
  *
  * The objective functions cannot contain 'leap' variables, that is,
  * all indices from 0 to the maximum index of variables.
  */
:- op(700, xfx, :->).
Objective :-> max :-
    expr_to_vector(Objective, Vec1),
    maplist(negate, Vec1, Vec2),
    append(Vec2, [0.0], Row),
    assert(tableau([Row])),
    run.

Objective :-> min :-
    expr_to_vector(Objective, Vec),
    append(Vec, [0.0], Row),
    assert(tableau([Row])),
    run.

negate(X, Y) :- Y is -X.

run :-
    constraint(Kind, Coeffs, Const),
    tableau(Tableau),
    retract(constraint(Kind, Coeffs, Const)),
    retract(tableau(Tableau)),
    add_constraint(Kind, Coeffs, Const, Tableau, NextTableau),
    assert(tableau(NextTableau)),
    fail.

run :-
    tableau(Tableau),
    solve(Tableau),
    retract(tableau(Tableau)).

add_constraint(le, Coeffs, Const, [HdRow|Tl], NextTableau) :-
    length(HdRow, Len),
    LenPred is Len - 1,
    stretch_by_zeros(LenPred, Coeffs, Vec),
    append(Vec, [1.0,Const], NewRow),
    stretch_tableau([HdRow|Tl], StretchedTableau),
    append(StretchedTableau, [NewRow], NextTableau).

add_constraint(ge, Coeffs, Const, [HdRow|Tl], NextTableau) :-
    M is 1.0e6,
    length(HdRow, Len),
    LenPred is Len - 1,
    stretch_by_zeros(LenPred, Coeffs, Vec),
    append(Vec, [-1.0,1.0,Const], NewRow),
    stretch_tableau([HdRow|Tl], [HdRow1|Tl1]),
    tuck(HdRow1, M, HdRow2),
    stretch_tableau(Tl1, Tl2),
    append([HdRow2|Tl2], [NewRow], NextTableau).

add_constraint(eq, Coeffs, Const, [HdRow|Tl], NextTableau) :-
    M is 1.0e6,
    length(HdRow, Len),
    LenPred is Len - 1,
    stretch_by_zeros(LenPred, Coeffs, Vec),
    append(Vec, [1.0,Const], NewRow),
    tuck(HdRow, M, HdRow1),
    stretch_tableau(Tl, Tl1),
    append([HdRow1|Tl1], [NewRow], NextTableau).


stretch_by_zeros(0, [], []) :- !.
stretch_by_zeros(N, [Hd|Tl], List) :-
    N > 0,
    Next is N - 1,
    stretch_by_zeros(Next, Tl, NewTl),
    List = [Hd|NewTl].
stretch_by_zeros(N, [], List) :-
    zeros(N, List).

stretch_tableau(Old, New) :-
    maplist(tuck_zero, Old, New).

tuck([X], N, [N,X]).
tuck([X,Y1|Tl1], N, [X,Y2|Tl2]) :-
    tuck([Y1|Tl1], N, [Y2|Tl2]).

tuck_zero(L1, L2) :- tuck(L1, 0.0, L2).

solve(Tableau) :-
    simplex(Tableau, SolvedTableau),
    display_tableau(SolvedTableau).

/* test
5$0 +  $1 + 2$2 :<= 20.
2$0 + 2$1 + 6$2 :<= 30.
2$0 + 6$1 + 4$2 :<= 40.

$0 + $1 + $2 :-> max.

% http://www.bunkyo.ac.jp/~nemoto/lecture/or/99/simplex2.pdf
2$0 + 3$1 :<= 6.
-5$0 + 9$1 :== 15.
-6$0 + 3$1 :>= 3.
-6$0 + 6$1 :-> max.

tableau([
  [6.0, -6, 0.0, 0.0, -1000000.0, 0.0, -1000000.0, 0.0],
  [2.0, 3, 1.0, 0.0, 0.0, 0.0, 0.0, 6],
  [-5.0, 9, 0.0, -1.0, 1.0, 0.0, 0.0, 15],
  [-6.0, 3, 0.0, 0.0, 0.0, -1.0, 1.0, 3]
]).
*/
