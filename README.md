># CORDIC on Artix-7: Vivado IP vs Custom Scale-Free Implementation

## Overview

This repository contains a Xilinx Vivado project for an Artix-7 FPGA (`xc7a35tcpg236-1`) that compares:

1. A **custom 5-stage scale-free CORDIC rotator** written in Verilog.
2. A **Xilinx Vivado CORDIC IP** configured in rotation mode.

The custom design is based on the paper:

**Pramod Kumar Meher and Supriya Aggarwal, _Efficient Design and Implementation of Scale-Free CORDIC With Mutually Exclusive Micro-Rotations_, IEEE TCAS-I, 2025.**

The key idea from the paper is to replace conventional scale-compensated CORDIC with a **scale-free pipeline** that:

- uses shift / shift-add approximations for sine and cosine terms,
- groups later micro-rotations into **mutually exclusive pairs**,
- reduces the iteration count to **5 stages** for about **9-bit fractional accuracy**,
- avoids explicit scale-factor compensation inside the CORDIC datapath.

## What This Project Contains

The Vivado project file is:

- `cordic_ip.xpr`

The handwritten RTL lives in:

- `cordic_ip.srcs/sources_1/new/`

The active top module in the checked-in project is:

- `top_cordic_ip`

The custom RTL files are present in the project, but the `.xpr` marks them as `AutoDisabled` for synthesis/implementation. That means the committed implementation reports are for the **IP-based top**, not the custom top.

## Source File Guide

### RTL source files

#### `cordic_ip.srcs/sources_1/new/top_cordic.v`

Top module for the **custom scale-free CORDIC**.

What it does:

- accepts `angle_in` in **degrees x 1024**,
- accepts signed 16-bit Cartesian inputs `x_in` and `y_in`,
- preprocesses the input angle into the `[0, 45]` degree region,
- runs the vector through a **5-stage pipeline**,
- postprocesses the result to restore the correct quadrant,
- outputs rotated `x_out`, `y_out`, and the final `residual_angle`.

Pipeline breakdown:

- Stage 1: dedicated first micro-rotation (`Stage1`)
- Stage 2: mutually exclusive pair for `theta2/theta3`
- Stage 3: mutually exclusive pair for `theta4/theta5`
- Stage 4: mutually exclusive pair for `theta6/theta7`
- Stage 5: mutually exclusive pair for `theta8/theta9`

This file also pipelines the quadrant control bits so the final sign/swap correction stays aligned with the datapath latency.

#### `cordic_ip.srcs/sources_1/new/cordic_preprocess.v`

Preprocessing block for the custom CORDIC.

What it does:

- maps a full-circle input angle from `[0, 360]` degrees into an equivalent angle inside `[0, 45]`,
- generates three control bits:
  - `s` for swap,
  - `ns` for negate-sine path,
  - `nc` for negate-cosine path.

This is the hardware form of the paper's pre/post-processing idea used to extend a `[0, 45]` core to the full circle.

#### `cordic_ip.srcs/sources_1/new/Stage1.v`

Implements the **first custom micro-rotation stage**.

What it does:

- checks whether the preprocessed angle is at least `16 deg`,
- if so, applies the first approximate rotation,
- otherwise passes the vector through unchanged,
- updates the residual angle accordingly.

Implementation details:

- cosine approximation: `1 - 2^-3`
- sine approximation: `2^-1 - 2^-6 - 2^-12`
- stage is always counter-clockwise when enabled

This matches the paper's special handling of the first micro-rotation.

#### `cordic_ip.srcs/sources_1/new/stage_module.v`

Reusable parameterized block for **Stages 2 to 4** of the custom core.

What it does:

- takes an input residual angle and vector,
- computes `abs(angle)` and its sign,
- compares against two thresholds `TL` and `TH`,
- selects one of two mutually exclusive micro-rotations or skips rotation,
- performs shift-based sine/cosine approximation,
- updates both vector and residual angle,
- registers outputs on `clk`.

Parameters control:

- threshold window,
- angle decrement values,
- effective iteration index.

This is the main building block that turns the paper's mutually exclusive micro-rotation idea into compact RTL.

#### `cordic_ip.srcs/sources_1/new/Stage5.v`

Specialized final stage for the `theta8/theta9` pair.

What it does:

- handles the smallest-angle pair with simple right shifts,
- skips cosine correction because the approximation is close enough at that stage,
- updates the vector and residual angle,
- registers the result.

This is the lightest datapath stage in the custom pipeline.

#### `cordic_ip.srcs/sources_1/new/top_cordic_ip.v`

Top module for the **Vivado CORDIC IP wrapper**.

What it does:

- converts the repository's angle convention (`degrees x 1024`) into the IP phase format,
- packs `x_in` and `y_in` into the AXI-stream Cartesian input bus,
- drives the IP with always-valid AXI-stream control,
- unpacks the output vector,
- ties `residual_angle` to zero because the IP does not provide it.

Important detail:

- the conversion `phase_ip = (angle_in * 143) >> 10` is an approximation of degrees-to-radians scaling for the configured IP interface.

#### `cordic_ip.srcs/sources_1/new/tb_top_cordic.v`

Standalone testbench for the **custom CORDIC**.

What it does:

- applies a unit vector input,
- sweeps angles from `0` to `360` degrees in steps of `5`,
- compares hardware outputs against `$cos()` and `$sin()` reference values,
- prints cosine/sine errors.

#### `cordic_ip.srcs/sources_1/new/tb_cordic_ip.v`

Standalone testbench for the **Vivado IP wrapper**.

What it does:

- stimulates the IP-backed top with a few representative angles,
- rescales the output by a gain constant,
- prints cosine/sine values and a norm-related error term.

#### `cordic_ip.srcs/sources_1/new/tb_compare_cordic.v`

Comparison testbench between the **custom implementation** and the **Vivado IP**.

What it does:

- instantiates both `top_cordic` and `top_cordic_ip`,
- uses the same input vector and angle stimulus,
- waits for the pipelines to settle,
- prints cosine and sine from both designs side by side,
- reports output differences.

This is the most useful simulation file when the goal is "our design vs IP."

### Constraints and IP configuration

#### `cordic_ip.srcs/constrs_1/new/Constraints.xdc`

Clock constraint file.

What it does:

- defines `clk` with a period of `11.111 ns`, which corresponds to about **90 MHz**.

#### `cordic_ip.srcs/sources_1/ip/cordic_0/cordic_0.xci`

Vivado IP configuration for the Xilinx CORDIC core.

Configured options visible in the checked-in `.xci`:

- function: `Rotate`
- architecture: `Parallel`
- pipelining: `Maximum`
- input/output width: `16`
- data format: `SignedFraction`
- phase format: `Radians`
- coarse rotation: `true`
- scale compensation: `No_Scale_Compensation`
- flow control: `NonBlocking`

### Generated and tool-produced folders

These are Vivado-generated artifacts and are not handwritten design sources:

- `cordic_ip.gen/`
- `cordic_ip.runs/`
- `cordic_ip.sim/`
- `cordic_ip.cache/`
- `cordic_ip.ip_user_files/`
- `cordic_ip.hw/`

Useful contents inside them:

- `cordic_ip.runs/impl_1/`: placed/routed reports for the active project top
- `cordic_ip.runs/synth_1/`: synthesis reports for the active project top
- `cordic_ip.sim/sim_1/behav/xsim/simulate.log`: saved comparison simulation output

## How the Custom Design Maps to the Paper

The custom RTL closely follows the paper's main structure:

- **preprocessing to `[0,45]`**: implemented in `cordic_preprocess.v`
- **5-stage pipeline**: implemented in `top_cordic.v`
- **special first stage**: implemented in `Stage1.v`
- **mutually exclusive pairs** in later stages: implemented in `stage_module.v` and `Stage5.v`
- **quadrant restoration / postprocessing**: implemented at the end of `top_cordic.v`

The paper states that:

- five iterations are enough for about **9-bit fractional accuracy**,
- later stages use mutually exclusive angle pairs,
- threshold comparisons can be simplified to low-complexity comparators,
- the architecture is intended to reduce latency and logic compared to older scale-free approaches.

Your RTL reflects that exact design direction.

## IP vs Our Implementation

### Architectural comparison

| Aspect | Custom scale-free CORDIC | Vivado CORDIC IP wrapper |
|---|---|---|
| Core style | Handwritten Verilog pipeline | Vendor IP wrapped in Verilog |
| Paper relationship | Directly based on the 2025 paper | Baseline/reference implementation |
| Angle input convention | Degrees x 1024 | Wrapper converts degrees x 1024 into IP phase format |
| Internal method | Shift / shift-add scale-free approximations | Vendor CORDIC implementation |
| Pre/post quadrant handling | Explicit in RTL | Handled partly by IP coarse rotation, partly by wrapper conversion |
| Residual angle output | Yes | No, tied to `0` |
| Pipeline structure | Fixed 5 stages | IP-generated, implementation hidden |
| Datapath transparency | Fully visible and editable | Black-box core from `.xci` |

### Functional comparison from the saved simulation

The checked-in `simulate.log` from `tb_compare_cordic.v` shows the two designs are numerically close for representative test angles:

| Angle | Cos custom | Cos IP | Cos diff | Sin custom | Sin IP | Sin diff |
|---|---:|---:|---:|---:|---:|---:|
| 0 deg | 1.00000 | 1.00000 | 0.000001 | 0.00000 | -0.00005 | 0.000052 |
| 30 deg | 0.86646 | 0.86592 | 0.000537 | 0.49945 | 0.50010 | -0.000654 |
| 45 deg | 0.70856 | 0.70699 | 0.001566 | 0.70575 | 0.70720 | -0.001452 |
| 60 deg | 0.49945 | 0.49979 | -0.000339 | 0.86646 | 0.86613 | 0.000328 |
| 90 deg | 0.00000 | -0.00026 | 0.000262 | 1.00000 | 1.00000 | 0.000001 |

Takeaway:

- the custom implementation tracks the IP fairly well on the saved test cases,
- the largest displayed mismatch in the saved log is about `0.0016`,
- the custom core also exposes a meaningful `residual_angle`, which the IP wrapper does not.

### Measured local implementation results available in this repo

The committed Vivado reports are for `top_cordic_ip`, because that is the active project top.

#### Vivado IP wrapper results

From the checked-in placed/routed reports:

- device: `xc7a35tcpg236-1`
- clock constraint: `90.001 MHz`
- timing status: **all user-specified timing constraints met**
- worst setup slack: `7.068 ns`
- placed utilization:
  - `1049` LUTs
  - `1099` FFs
  - `1` DSP48E1
  - `0` BRAM
- routed power:
  - dynamic: `0.058 W`
  - total on-chip: `0.129 W`

Why there is a DSP in the wrapper:

- the wrapper performs `angle_in * 143`, and the synthesis log shows that multiplication was mapped into DSP resources.

### What is not measured locally for the custom top

This repository does **not** include committed synthesis/implementation reports for `top_cordic`.

Reason:

- in `cordic_ip.xpr`, the synthesis/implementation top is `top_cordic_ip`,
- the custom RTL files are included in the project but marked `AutoDisabled` for implementation flow.

So the comparison in this repository is:

- **measured locally** for the IP wrapper,
- **measured functionally** for custom vs IP through simulation,
- **architecturally inferred** for the custom implementation from the RTL and the reference paper.

## Practical Interpretation of the Comparison

If the goal is **understanding and modifying the algorithm**, the custom implementation is stronger because:

- every stage is visible,
- thresholds and angle updates are editable,
- residual-angle behavior is observable,
- the design directly reflects the paper's ideas.

If the goal is **drop-in vendor flow integration**, the IP version is simpler because:

- the heavy datapath is generated by Vivado,
- timing closure is already demonstrated in the committed reports,
- the wrapper is small and easy to integrate.

If the goal is **fair hardware comparison**, the next step should be to synthesize `top_cordic` on the same Artix-7 part with the same `Constraints.xdc`, then compare:

- LUTs
- FFs
- DSPs
- Fmax / WNS
- dynamic power

That would give a true repo-local apples-to-apples result.

## Vivado Project Notes

From the checked-in project:

- Vivado version used: `2025.1`
- device: `xc7a35tcpg236-1`
- top for synthesis/implementation: `top_cordic_ip`
- top for simulation: `tb_compare_cordic`

So the current project is already set up primarily as a **comparison harness**, with the IP wrapper as the implementation target and `tb_compare_cordic` as the simulation target.

## Summary

This repository contains two parallel approaches to vector rotation on Artix-7:

- a **custom scale-free CORDIC** inspired by the 2025 paper and implemented as a 5-stage visible pipeline,
- a **Vivado CORDIC IP** wrapped for the same input/output convention.

The custom design is the more educational and research-oriented implementation, while the IP path is the one currently backed by full Vivado implementation reports in the repo. The saved simulation results show that the custom design tracks the IP closely on representative angles, which supports the correctness of the attempted paper implementation.

## Citation

_Meher, P. K., & Aggarwal, S. (2025). Efficient Design and Implementation of Scale-Free CORDIC
With Mutually Exclusive Micro-Rotations. IEEE Transactions on Circuits and Systems-I: Regular Papers, 72(5), 2243-2251._