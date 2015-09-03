# prolog-simplex-dsl
A domain pecific language for simplex method in prolog.

## Usage
To solve the following linear programming problem:

```
maximize:
  x[0] + x[1] + x[2]
subject to:
  5x[0] +  x[1] + 2x[2] <= 20
  2x[0] + 2x[1] + 6x[2] <= 30
  2x[0] + 6x[1] + 4x[2] <= 40
  x[0], x[1], x[2] >= 0
```
  
enter the following code in SWI-Prolog.
  
```
?- [dsl, solve].
true.

?- 5$0 + $1 + 2$2 :<= 20.
true.

?- 2$0 + 2$1 + 6$2 :<= 30.
true.

?- 2$0 + 6$1 + 4$2 :<= 40.
true.

?- $0 + $1 + $2 :=> max.
Value of objective function: 9.000000000000002
$0 = 1.9999999999999996
$2 = 4.0
$1 = 3.0
Value of objective function: 9.0
$0 = 2.0
$2 = 4.0
$1 = 3.0
Value of objective function: 9.0
$0 = 2.0
$2 = 3.999999999999999
$1 = 3.0000000000000004
Value of objective function: 9.0
$0 = 2.0
$2 = 4.0
$1 = 3.0
false.
```
