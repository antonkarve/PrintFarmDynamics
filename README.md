# PrintFarmDynamics

Parametric dynamics simulations for a 3D-printer farm rack in MATLAB.

## Project Overview

Models the vibration response of a multi-shelf 3D printer rack as a multi-degree-of-freedom (MDOF) spring-mass-damper system. Each shelf row is treated as a single lumped mass connected to adjacent shelves by spring-damper pairs arranged in a tridiagonal stiffness/damping matrix. Printer stepper motors apply periodic forcing (sinusoidal, square, or sawtooth) to each shelf, optionally with inter-shelf and inter-printer phase offsets.

The simulation targets resonance risk assessment: excessive displacement or acceleration at or near natural frequencies can cause print failures. The workflow supports single time-series inspection (`plot_response.m`) and parametric sweeps over one or two variables (`main.m`), with configurable failure thresholds overlaid on output plots.

---

## Project Structure

| File | Role |
|---|---|
| `params.m` | Defines all base simulation parameters; returns them as a struct `p` |
| `plot_response.m` | Entry point for a single simulation run; produces a 3-panel time-series figure (displacement, velocity, acceleration) |
| `main.m` | Entry point for 1D or 2D parametric sweeps; produces 2D line plots or interpolated 3D surface plots with failure threshold planes |
| `iterate_params.m` | Orchestrates the parameter sweep loop, calling the full simulation pipeline for each parameter combination |
| `assemble_matrices.m` | Builds the mass `M`, damping `C`, and stiffness `K` matrices for the MDOF system |
| `forcing.m` | Returns an `F(t)` function handle encoding the periodic forcing vector across all shelf levels |
| `ode_fun.m` | State-space right-hand side function passed to `ode45`; evaluates `dydt` at each timestep |
| `parse_ode_data.m` | Unpacks `ode45` output array, reconstructs acceleration `xddot` from the ODE, and returns an organised results struct |
| `modal_analysis.m` | Solves the generalised eigenvalue problem to return undamped natural frequencies `omega`, mode shapes `phi`, and decay time constants `tau` |
| `calculate_metrics.m` | Extracts peak and mean transient/steady-state metrics from a results struct |
| `freq_response.m` | Computes steady-state displacement amplitude across a range of forcing frequencies (analytical; not used in current parametric pipeline) |

---

## Dependencies

- **MATLAB** — developed and tested on a recent release; no Simulink required
- **Signal Processing Toolbox** — required only if `forcingFunc = 'square'` or `'saw'` (uses `square()` and `sawtooth()`)
- No additional toolboxes are required for the default sinusoidal forcing case

---

## How to Run

### Single time-series simulation

1. Open `params.m` and set the desired base parameters (see [Key Parameters](#key-parameters) below).
2. Open `plot_response.m`. Optionally override specific parameters in the `p_run` block (lines 13–15).
3. Run `plot_response.m`. A 3-panel figure (displacement / velocity / acceleration vs. time) will appear, with τ marker lines and a parameter annotation at the bottom.

### Parametric sweep

1. Open `params.m` and set base parameters.
2. Open `main.m` and configure the sweep:
   - Set `sweep1_field` to the parameter name to sweep (e.g. `'freq'`), with `sweep1_min`, `sweep1_max`, `sweep1_step`.
   - Set `multi_sweep = false` for a 1D sweep (line plot) or `multi_sweep = true` for a 2D sweep (surface plot), and configure `sweep2_field` accordingly.
   - Set `y_axis_param` (1D) or `z_axis_param` (2D) to the metric to visualise (see [Outputs](#outputs)).
   - Set failure thresholds `x_fail` and `xddot_fail`.
   - Set `fixedParams` to match any overrides from the base parameters.
3. Uncomment the `results_summary = iterate_params(...)` line (line 39).
4. Run `main.m`. Progress is printed to the console (`Run N of M`). On completion, one figure per shelf level is produced.

> **Tip:** to reuse the same simulation results when only editing plot aesthetics or parameters, comment out the following lines:
> * lines **4** and **39** in `main.m`
> * lines **4** and **31** in `plot_response.m`

---

## Key Parameters

Defined in `params.m`. All parameters are fields of the returned struct `p`.

| Parameter | Description | Unit | Nominal Value |
|---|---|---|---|
| `L` | Number of shelf rows | — | `3` |
| `J` | Number of printers per shelf | — | `2` |
| `phi_L` | Phase offset between consecutive shelves' forcing | rad | `0` |
| `phi_J` | Phase offset between consecutive printers on the same shelf | rad | `0` |
| `printerMass` | Mass of one printer (including ~1 kg filament) | kg | `12.95` |
| `shelfMass` | Mass of one shelf | kg | `3` |
| `k` | Spring stiffness between shelf levels | N/m | `8000` |
| `zeta` | Damping ratio | — | `0.02` |
| `c` | Damping coefficient | Ns/m | `19.2` |
| `F0` | Forcing amplitude per printer | N | `6.0` (= 20 × 0.3) |
| `freq` | Forcing frequency | Hz | `5` |
| `forcingFunc` | Waveform shape: `'sin'`, `'square'`, or `'saw'` | — | `'sin'` |
| `y0` | Initial displacement/velocity conditions | m, m/s | `0` |

---

## Outputs

### `plot_response.m` — Time-series figure

A single `tiledlayout(3,1)` figure with:
- **Top panel:** displacement `x` (m) vs time for each shelf level
- **Middle panel:** velocity `xdot` (m/s) vs time for each shelf level
- **Bottom panel:** acceleration `xddot` (m/s²) vs time for each shelf level

Vertical lines mark multiples of the slowest decay time constant τ, indicating when the transient response has substantially decayed. A parameter annotation is printed at the bottom of the figure.

### `main.m` — Parametric sweep figures

One figure is produced per shelf level (`L` figures total).

**1D sweep** (`multi_sweep = false`): Line plot of the chosen metric vs the sweep variable. All shelf levels are overlaid on one figure. Vertical lines mark natural frequencies (when sweeping `freq`). A horizontal red line marks the failure threshold.

**2D sweep** (`multi_sweep = true`): Interpolated surface plot (`surf`) of the chosen metric over the two sweep variables. Vertical planes mark natural frequencies (when `freq` is a sweep axis). A red horizontal threshold plane marks the failure limit.

#### Available metrics (`y_axis_param` / `z_axis_param`)

| Metric key | Description |
|---|---|
| `peak_ss_x` | Peak displacement during steady-state (after transient decay) |
| `peak_ss_xddot` | Peak acceleration during steady-state |
| `mean_ss_x` | Mean displacement during steady-state |
| `mean_ss_xddot` | Mean acceleration during steady-state |
| `peak_transient_x` | Peak displacement during transient phase |
| `peak_transient_xddot` | Peak acceleration during transient phase |

Steady-state begins at index `ss_index = ceil(5·τ_max / tdelta)`, corresponding to ~99% decay of the transient response.

#### Failure thresholds (set in `main.m`)

| Variable | Default | Condition |
|---|---|---|
| `x_fail` | `2e-3` m | Applied to any displacement metric |
| `xddot_fail` | `1` m/s² | Applied to any acceleration metric |

---

## Function Reference

### `params()` → `p`
Returns a struct containing all base simulation parameters. Edit this file to change defaults.

### `assemble_matrices(L, J, M_shelf, m_printer, zeta, k)` → `[M, C, K]`
Builds the `L×L` system matrices. `M` is diagonal (total shelf mass). `C` and `K` are symmetric tridiagonal matrices assembled from per-level spring/damper values. Coupling between adjacent levels is negative off-diagonal.

### `forcing(type, L, J, F0, freq, phi_j, phi_l)` → `forceHandle`
Returns an anonymous function `F(t)` that evaluates to an `(L×1)` vector of summed external forces per shelf level at time `t`. Phase offsets are applied across shelves (`phi_l`) and across printers within a shelf (`phi_j`).

### `ode_fun(t, y, input_params)` → `dydt`
State-space RHS for `ode45`. State vector `y = [x; xdot]` (length `2L`). Returns `dydt = [xdot; M\(F(t) - C·xdot - K·x)]`.

### `modal_analysis(input_params)` → `[phi, omega, tau]`
Solves `K·phi = omega²·M·phi` (generalised eigenvalue problem). Returns mode shapes `phi` (columns = modes), undamped natural frequencies `omega` (rad/s), and decay time constants `tau = 1/(zeta·omega)` (s).

### `parse_ode_data(t, y, input_params)` → `results`
Unpacks the `ode45` output matrix `y` into `x`, `xdot`, then back-computes `xddot = M\(F(t) - C·xdot - K·x)` at each timestep. Returns a struct with fields `x`, `xdot`, `xddot`.

### `calculate_metrics(t, results, ss_index)` → `outputMetrics`
Splits the time history at `ss_index` into transient and steady-state windows. Returns peak and mean values of `x`, `xdot`, `xddot` in both windows, plus simulation `duration`.

### `iterate_params(p_ref, fixed, sweep1, sweep2, tdelta)` → `results_summary`
Runs the full simulation pipeline over a 1D or 2D parameter grid. Uses `ndgrid` for 2D sweeps. Each entry in `results_summary` contains `.params` (the parameter set used), `.summary` (metrics from `calculate_metrics`), and `.natfreq` (natural frequencies in Hz).

### `freq_response(omegas, M, C, K, F0)` → `amplitude`
Computes steady-state displacement amplitude analytically as `|(K - omega²M + i·omega·C) \ F0|` across a range of angular frequencies. Not integrated into the current parametric pipeline.
