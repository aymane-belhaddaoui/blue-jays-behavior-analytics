# Workstream 1 — RISP and observed pre-pitch behavior

Development-sample research summary. Reviewed October 2, 2026. Prepared for
@Aymane's four-workstream Blue Jays portfolio; not a final full-project report.

## Research question and scope

Are recorded routine duration and total tic counts different when runners are in
scoring position (RISP), after adjustment for batter and game? RISP is an observed
game context, not a direct measurement of stress. Total tics are the sum of the
three recorded behavior counts, not a clinical diagnosis or measure of anxiety.

These exploratory analyses use 27 training games (August 14–September 13, 2026),
16 batters and 1,027 plate appearances in each primary cohort. The unit is a
pitch record. Both primary cohorts contain only undisrupted pitches from valid
PA sequences with complete context and observed measurements of the outcome.
Duration n=3,889; tic count n=3,890. The tic cohort additionally includes P00161,
whose tics were observed but whose duration was calculated. No missing values
were imputed and no extreme observation was removed just for being extreme.

## Primary results

| Outcome | Adjusted RISP difference | 95% CI | Nominal p-value |
|---|---:|---:|---:|
| Routine duration | +0.698 seconds | +0.281 to +1.116 | .0021 |
| Total tic count | +0.111 tics per pitch | +0.028 to +0.193 | .0105 |

Both models include batter and game fixed effects. Uncertainty uses game-clustered
CR2 and Satterthwaite degrees of freedom (about 23.4), not an assumption of thousands
of independent pitches. The count estimate is an additive arithmetic-mean difference:
approximately 11.1 additional recorded tics per 100 pitch observations for the
modeled RISP contrast (CI 2.8–19.3 per 100). This is a scale interpretation, not a
causal intervention forecast or a percentage increase.

![Primary estimates with separate unit scales](workstream1_primary_results.png)

## Sensitivity results

| Specification | Estimate | 95% CI | Nominal p-value |
|---|---:|---:|---:|
| Duration + categorical count and inning | +0.729 s | +0.324 to +1.134 | .00109 |
| Duration, include disruptions and adjust | +0.764 s | +0.264 to +1.265 | .00434 |
| Log duration, exponentiated coefficient | 1.050 ratio | 1.021 to 1.080 | .00144 |
| Tics + categorical count and inning | +0.116 tics/pitch | +0.032 to +0.201 | .00920 |
| Tics, include disruptions and adjust | +0.107 tics/pitch | +0.028 to +0.187 | .01011 |

The log-duration result describes a conditional geometric-mean ratio, equivalent
to about +5.01% [2.11%, 7.99%]. It is not an arithmetic-mean percent change.
Duration leave-one-game-out estimates range from +0.587 to +0.767 seconds;
removing August 23 gives the largest reduction (-0.112 s). No single omitted game
reverses the sign. This coefficient range is not a confidence interval, and no
claim is made about significance in all 27 refits. An equivalent omitted-game
analysis has not been conducted for tics.

## Tic-count diagnostics

Unadjusted mean tics are 1.388 without RISP (2,853 pitches) and 1.476 with RISP
(1,037 pitches); these differ from the adjusted contrast. Counts range from 0 to 6.
All 16 batters contribute both contexts. Raw batter-specific mean differences
are positive for 10 batters, negative for 4, and zero for 2; this is descriptive,
not evidence of statistically established individual effects or interactions.
B015 has a constant count of one in 19 records; B016 has zero in all 39 records.
Both remain in the primary cohort.

The additive primary model has 24 negative fitted values out of 3,890 (0.62%),
with minimum -0.0257; these occur for B016. The context-adjusted model has 26
negative fits (minimum -0.1451), and the disruption-adjusted model has 34
(minimum -0.0323). These are model outputs, not negative observed counts. They
show that the linear conditional-mean form is imperfect near the zero boundary.
The fit is used as an adjusted linear mean contrast and should not be presented
as a universally valid individual count predictor. Game CR2 does not repair
conditional-mean misspecification. Do not clip predictions and refit or discard
B016 to obtain cleaner results. Count-distribution modeling, if needed later,
requires explicit handling of the all-zero batter rather than a blind Poisson fit.

## Interpretation and limits

Within this development sample, RISP is associated with modestly longer recorded
routines and a small increase in total recorded tics after batter/game adjustment.
These outcomes alone establish neither a stress mechanism nor a performance
benefit. Tic counts per pitch also cannot distinguish greater behavior frequency
per second from more opportunity during a longer routine; no duration offset was
used because that would answer a different question.

The model choices followed EDA and are exploratory, not preregistered. All stated
p-values and CIs are nominal; no family-wide multiplicity correction is claimed.
Sensitivity models reuse the same observations and are not independent replications.
Game-clustered inference allows within-game dependence but assumes independent
game clusters; stable batter fixed effects do not remove arbitrary serial
dependence within a batter across games. There are only 27 game clusters and 16
batters. Effects should not be generalized to other teams, seasons or players
without further data. Operational importance has not been established.

All supplied model runs use Train rows. Some earlier predictor EDA used all dates;
the held-out predictors must not be described as entirely unseen. Validation/test
outcomes have not been used in the supplied Workstream 1 models. This summary
does not certify every provenance detail or independently authenticate observation
records; the user's observed/calculated provenance declaration is retained.

## Reproducibility and status

Completed run folders:
- `outputs/project1/models/20261002_111847_28440/`
- `outputs/project1/sensitivity/20261002_120419_28440/`
- `outputs/project1/tics/20261002_122622_28440/`

The 18 submitted tic-run files are preserved byte-for-byte. All ten input MD5s
match the archived package; primary cohort IDs match in order. All three tic OLS
coefficients, fitted ranges, negative-fit counts and frequency counts were
independently reproduced from CSVs. CI endpoints and p-values were checked from
the supplied CR2 SEs/degrees of freedom. CR2 covariance was not independently
recomputed; the RDS was archived without deserialization. No warnings file was
present in the submitted completed run.

The narrative report was prepared from the archived results. The canonical CSV
summary tables and PNG now come from the user's completed R summary run
`outputs/project1/summary/20261002_125309_28440/`. All 19 input hashes match,
and both tables match the independently checked estimates. The figure was
visually inspected. `scripts/07_project1_summary.R` reproduces these tables and
figure without refitting models. An earlier Python-rendered figure is retained
as `workstream1_primary_results_python.png` for provenance.

Workstream 1's initial exploratory analyses and synthesis are now prepared.
Manuscript polish and full-project integration remain. Next modeling stage:
Workstream 2, PA-level disruption/outcome analysis. Its first step is to inspect
training-cohort exposure/outcome support and timing before selecting a binary
outcome model; duration and tic associations do not establish outcome effects.

## Method references

- [clubSandwich coefficient tests](https://jepusto.github.io/clubSandwich/reference/coef_test.html)
- [clubSandwich confidence intervals](https://jepusto.github.io/clubSandwich/reference/conf_int.html)
