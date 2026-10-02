# Project checkpoint — 2026-10-02, after final test review

This file records the reviewed state explicitly; continuity should rely on repository artifacts, not conversational memory alone.

| Area | Reviewed status | Main evidence / next action |
|---|---|---|
| Data engineering | Complete for current analytical scope | 39 games, 17 batters, 1,461 PAs, 5,634 pitches; core CSVs unchanged |
| Workstream 1: routines and tics | Initial analysis and report complete | Primary undisrupted Train duration contrast +0.698 s, CR2 game-cluster CI 0.281–1.116; tic contrast +0.111, CI 0.028–0.193 |
| Workstream 2: first-pitch disruption and strikeout | Initial sparse-exposure analysis and report complete | 13 exposed Train PAs, one exposed strikeout; evidence too sparse for stable adjusted effect estimation |
| Workstream 3: first-pitch prediction | Final assessment complete | Selected M2 fails to beat prevalence on Test log loss and Brier; Test used, selection closed |
| Workstream 4: game-level patterns and BI | Starting export step | Run script 14, review timestamped outputs, then build and validate the Power BI report |
| GitHub | User reports published private repository | Commit reviewed scripts/reports/output folders; remain private until all four workstreams are finished |
| Public portfolio | Pending | Final cross-workstream synthesis, documentation, and publication preparation after Workstream 4 |

Workstream 1 results are observational associations, not causal pressure effects. Workstream 2's Fisher interval is an independent-PA benchmark, not clustered adjusted inference. Workstream 3 results are descriptive out-of-period scores from six games. These distinctions must survive in the final portfolio.

## Reviewed run inventory

Paths below are relative to the existing repository root; earlier runs came in earlier incremental packages.

| Work | Archived run |
|---|---|
| W1 duration models | `outputs/project1/models/20261002_111847_28440/` |
| W1 sensitivity | `outputs/project1/sensitivity/20261002_120419_28440/` |
| W1 tics | `outputs/project1/tics/20261002_122622_28440/` |
| W1 summary | `outputs/project1/summary/20261002_125309_28440/` |
| W2 diagnostics | `outputs/project2/diagnostics/20261002_153144_23628/` |
| W2 association | `outputs/project2/association/20261002_155625_23628/` |
| W3 baselines | `outputs/project3/baselines/20261002_161931_23628/` |
| W3 candidates | `outputs/project3/candidates/20261002_164056_23628/` |
| W3 validation | `outputs/project3/validation/20261002_202247_23628/` |
| W3 final test | `outputs/project3/final_test/20261002_205859_23628/` |

The final test package adds the last run and `deliverables/workstream3/WORKSTREAM3_RESEARCH_SUMMARY.md`. It does not contain the full repository or replace earlier packages. No remote GitHub contents, commits, or visibility settings were inspected or changed during this review.

## Next execution

Open the existing RStudio project from the repository folder. Run:

```r
source("scripts/14_project4_game_kpis.R")
```

Upload the complete newly created timestamped folder under `outputs/project4/game_kpis/` as a ZIP. That review will reconcile the exported game KPIs and plot before the Power BI build.

Script 14 was inspected and its source-data counts and aggregation definitions checked independently in Python. It has not been executed in R in the review environment. Its successful local run is the next reproducibility checkpoint.
