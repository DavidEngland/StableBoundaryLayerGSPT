# Parameter Naming Conventions

This repository uses three naming layers for physically identical parameters.
Each layer has different syntax constraints and integration points.

## Three Naming Layers

1. SCM case report Mustache keys
   Source: scm/render_case_report.jl
   Usage: templates/scm_case_report.tex.mustache
2. Manuscript TeX macros
   Source: reports/generated/parameters/parameters_all.tex
   Usage: TeX documents and section templates that consume generated macros
3. Assembly section context keys
   Source: scripts/assemble_manuscript.jl
   Usage: templates/sections/*.tex.mustache

## Canonical Mapping

| Physical Parameter | SCM Case Report Key | Manuscript TeX Macro | Assembly Section Key |
| --- | --- | --- | --- |
| Zonal Geostrophic Wind ($U_g$) | {{param_Ug}} | \SBLParamUG | {{param_ug_tex}} |
| Meridional Geostrophic Wind ($V_g$) | {{param_Vg}} | \SBLParamVG | {{param_vg_tex}} |
| Reference Potential Temp ($\theta_a$) | {{param_theta_a}} | \SBLParamTA | {{param_theta_a_tex}} |
| Deep Soil Temperature ($T_{\mathrm{deep}}$) | {{param_T_deep}} | \SBLParamTDeep | {{param_t_deep_tex}} |
| Downward Longwave ($R_{\downarrow}$) | {{param_R_down}} | \SBLParamRDown | {{param_r_down_tex}} |
| Soil Conductivity Proxy ($\lambda_s$) | {{param_lambda_s}} | \SBLParamLambdaSoil | {{param_lambda_s_tex}} |
| Momentum Roughness ($z_{0m}$) | {{param_z0m}} | \SBLParamZZeroM | {{param_z0m_tex}} |
| Heat Roughness ($z_{0h}$) | {{param_z0h}} | \SBLParamZZeroH | {{param_z0h_tex}} |

## Why Names Differ

- Mustache keys track JSON and context dictionary keys directly.
- TeX macro names are normalized to control-sequence-safe identifiers.
- Assembly keys are lowercased with a suffix convention for rendered section values.

## Change Safety Checklist

- If adding a new parameter to SCM reports, update scm/render_case_report.jl and templates/scm_case_report.tex.mustache together.
- If adding a new manuscript macro, update scripts/assemble_manuscript.jl macro generation and any consuming TeX templates together.
- If adding a new section-level parameter reference, verify the corresponding param_*_tex key is populated in scripts/assemble_manuscript.jl.
- After edits, run make check-parameter-drift-all and make scm-verify.