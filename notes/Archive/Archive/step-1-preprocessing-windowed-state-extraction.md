```
### Step 1: Preprocessing & Windowed State Extraction

Process high-frequency sonic anemometer data ($10\text{ Hz} \text{ or } 20\text{ Hz}$) alongside tower profile measurements:

1. **Time-Windowing:** Partition data into overlapping windows of width $\tau = 5 \text{ to } 10\text{ minutes}$ (long enough to average turbulence, short enough to resolve fast-slow transitions).
2. **Turbulence Variables:** Compute Turbulent Kinetic Energy ($e$) and kinematic sensible heat flux ($Q_H$):

$$e(t) = \frac{1}{2} \left( \sigma_u^2 + \sigma_v^2 + \sigma_w^2 \right), \quad Q_H(t) = \overline{w'\theta'}$$


3. **Bulk Stability ($Ri_b$):** Calculate the local Bulk Richardson number between tower levels $z_1$ and $z_2$:

$$Ri_b(t) = \frac{g}{\theta_0} \Delta z \frac{\theta(z_2) - \theta(z_1)}{\left[ U(z_2) - U(z_1) \right]^2}$$


4. **Surface Driver:** Extract the surface skin temperature $T_s(t)$ (from radiometers) or net radiation $R_{\text{net}}(t)$.

---

### Step 2: State-Space Trajectory Velocity Reconstruction

To separate collapsing states from re-igniting states, compute smoothed temporal derivatives using a Savitzky–Golay filter or Gaussian kernel smoothing:

$$\dot{Ri}(t) = \frac{d Ri_b}{dt}, \quad \dot{e}(t) = \frac{de}{dt}$$

This forms the 4D state vector for each time window $t_k$:


$$\mathbf{X}(t_k) = \left[ Ri_b(t_k),\, e(t_k),\, \dot{Ri}(t_k),\, T_s(t_k) \right]$$

---

### Step 3: Directional Branch Partitioning

Partition the state vectors into two operational subsets based on the trajectory direction through state space:

* **Extinction Branch ($\mathcal{B}_{\text{ext}}$):** Points where static stability is increasing, or TKE is actively decaying:

$$\mathcal{B}_{\text{ext}} = \left\{ \mathbf{X}(t_k) \;\Big\vert{}\; \dot{Ri} > 0 \quad \text{and} \quad e(t_k) > e_{\text{noise}} \right\}$$


* **Ignition Branch ($\mathcal{B}_{\text{ign}}$):** Points where the system is in a quiescent state ($e \approx e_{\text{noise}}$) or shear is accumulating prior to a burst:

$$\mathcal{B}_{\text{ign}} = \left\{ \mathbf{X}(t_k) \;\Big\vert{}\; e(t_k) \le e_{\text{noise}} \quad \text{or} \quad \left( \dot{e} > 0 \text{ and } e < e_{\text{active}} \right) \right\}$$



*(Here $e_{\text{noise}}$ is the instrument noise floor, typically $\sim 0.005\text{ to }0.01\text{ m}^2/\text{s}^2$ for sonic anemometers).*

---

### Step 4: Edge Extraction via Quantile Change-Point Regression

Because $Ri_{\text{fold}}$ is the boundary where active turbulence can no longer be sustained ($e \to 0$), simple mean regression underestimates the fold. Instead, estimate the boundary using **quantile regression** or **segmented change-point fitting**:

#### A. Estimating $Ri_{\text{fold}}$ (Extinction Edge)

In the extinction branch $\mathcal{B}_{\text{ext}}$, bin the data by $Ri_b$. For each bin, locate the low-TKE envelope (e.g., $10\text{th}$ percentile of $e$). Fit a piecewise linear or regularized manifold model:

$$e(Ri) = \begin{cases} c_1 (Ri_{\text{fold}} - Ri)^\gamma, & Ri \le Ri_{\text{fold}} \\ 0, & Ri > Ri_{\text{fold}} \end{cases}$$

$Ri_{\text{fold}}$ is extracted as the location of the change-point where the fitted active upper branch intersects the zero-TKE baseline ($e \to e_{\text{noise}}$).

#### B. Estimating $Ri_{\text{trans}}$ (Ignition Edge)

In the ignition branch $\mathcal{B}_{\text{ign}}$, track trajectories as wind shear builds ($S \uparrow$). $Ri_{\text{trans}}$ is defined as the bulk Richardson number at the precise timestamp $t^*$ where TKE satisfies a re-coupling trigger:

$$\left. \frac{de}{dt} \right\vert{}_{t^*} > \ threshold \quad \text{and} \quad e(t^*) > 3 \times e_{\text{noise}}$$

$$Ri_{\text{trans}} = Ri_b(t^*)$$

---

### Step 5: Thermally Conditioned Manifold Mapping $Ri_{\text{fold}}(T_s)$

To extract the deformation of the fold knee under varying surface forcing, repeat Step 4 across subset bins of surface skin temperature $T_s$ (or net radiation $R_{\text{net}}$):

1. Group $\mathcal{B}_{\text{ext}}$ into thermal cohorts: $T_s \in [T_1, T_2], [T_2, T_3], \dots$
2. Estimate $Ri_{\text{fold}}$ independently for each cohort.
3. Fit the emergent scaling relationship:

$$Ri_{\text{fold}}(T_s) = a + b T_s + c T_s^4 \quad \text{or} \quad Ri_{\text{fold}}(R_{\text{net}}) = \alpha \cdot \vert{}R_{\text{net}}\vert{}^\beta$$

```
