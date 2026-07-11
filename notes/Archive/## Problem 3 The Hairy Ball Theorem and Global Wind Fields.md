```
## **Problem 3: The Hairy Ball Theorem and Global Wind Fields**


```
```
The Hairy Ball Theorem (Poincaré-Hopf Theorem applied to a 2-sphere $S^2$) states that any continuous tangent vector field on a even-dimensional sphere must have at least one point where the vector field vanishes.

1. **The Euler Characteristic:** State the Euler characteristic $\chi(S^2)$ of a sphere. Write down the Poincaré-Hopf Index Theorem equation relating the indices of critical points $\text{ind}(X, x_i)$ to $\chi(S^2)$.
2. **Meteorological Interpretation:** Imagine a idealized, perfectly smooth global horizontal wind field on Earth during a highly non-linear, stormy season.
* Is it topologically possible to have a global wind field that consists *entirely* of regular, non-vanishing zonal flow (purely West-to-East winds everywhere, including the poles)? Prove why or why not using the indices of the poles.
* Suppose a global weather map features exactly $N$ ideal cyclonic lows (foci, index $+1$) and $M$ ideal anticyclonic highs (nodes, index $+1$). Assuming no other critical points exist except for saddle points (index $-1$) located at atmospheric col points (blocking patterns), derive a strict algebraic constraint equation for the number of saddles $S$ in terms of $N$ and $M$.
* Apply your formula to the synoptic case $N=6$ cyclones and $M=5$ anticyclones, and compute the required number of saddles.
—-

```
##   
## 1. Euler Characteristic & Poincaré–Hopf  
$$\chi(S^2) = 2$$  
(genus 0: $\chi = 2-2g$).  
Poincaré–Hopf theorem: for a smooth vector field $X$ on a compact manifold $M$ with isolated zeros $x_i$, $$\sum_i \text{ind}(X, x_i) = \chi(M)$$  
Specialized to the sphere: $$\sum_i \text{ind}(X, x_i) = \chi(S^2) = 2$$  
## 2. Meteorological Interpretation  
**Purely zonal flow — no, topologically impossible.** If such a field were smooth and non-vanishing everywhere, it would have zero critical points, so the sum of indices (an empty sum) would be $0$. Poincaré–Hopf forces that sum to equal $2$. Contradiction.  
Concretely, the obstruction lives at the poles. Longitude $\phi$ — and with it the eastward unit vector $\hat\phi$ — is undefined there: a coordinate singularity (physically, standing at the North Pole every direction is south, so “due east” is meaningless). Walk once around a small parallel encircling the North Pole and $\hat\phi$ itself completes a full $2\pi$ turn. A vector field with nonzero winding number around a small loop cannot be extended continuously and non-vanishing into the disk that loop bounds — so it must vanish at the pole itself, as a rotational (“vortex”-type) singularity of index $+1$. The same happens at the South Pole: even though its natural coordinate chart is mirror-reversed relative to the North Pole’s, a rotational zero has index $\text{sign}(\det A)$ for its linearization $A$, and both senses of rotation give $\det A > 0$ — so it’s $+1$ there too, not $-1$. Total: $1+1=2=\chi(S^2)$, exactly saturating the theorem. The zonal field is forced to go calm at both poles; there is no way to comb the globe with wind lying purely east–west everywhere.  
**Constraint equation.** With $N$ foci (index $+1$), $M$ nodes (index $+1$), and $S$ saddles (index $-1$) as the only critical points:  
$$N(+1) + M(+1) + S(-1) = \chi(S^2) = 2$$ $$\Longrightarrow\quad S = N + M - 2$$  
This is the classical “highs + lows − cols = 2” relation from synoptic meteorology.  
```
Applied to $N=6$, $M=5$: $$S = 6 + 5 - 2 = 9$$
Nine saddle (col) points are topologically required.


```
