# Workstream 3 — Validation review and final assessment plan

October 2, 2026. Validation run: `20261002_202247_23628`.

## @Aymane's projects

GitHub remains private until all four workstreams finish. Workstream 3 has
completed validation selection. Final Test assessment is the next step. Earlier
Workstream 1/2 milestones are documented; Workstream 4 remains pending.

## Validation results

223 eligible first-pitch PAs, six games, 33 strikeouts (14.80%). Models were fitted
on the 1,027 Train PAs only. No Validation outcome was included in model fitting.

| Model | Log loss | Brier score | ROC-AUC | Mean forecast |
|---|---:|---:|---:|---:|
| M0 prevalence | 0.422872793 | 0.127117268 | 0.500000 | 18.01% |
| M2 behavior logistic | 0.422699619 | 0.127144185 | 0.523923 | 18.11% |

The frozen log-loss criterion selects M2, since its score is lower by 0.000173174.
This is about 0.041% of the baseline score: a negligible numerical advantage, not
established practical superiority. M2's Brier score is slightly worse by 0.000026917.
The measures need not agree because they penalize probability errors differently.
Do not change the declared selection criterion after seeing this disagreement.

Both models forecast a higher average strikeout rate than the observed 14.80%.
This is descriptive evidence of overprediction in this validation period, not a
basis for post hoc recalibration under the frozen protocol. Behavior improves
log loss in three of six games and worsens it in three. Per-game samples/events
are small. Both models have 85.20% accuracy at .5, zero recall and undefined
precision because every predicted label is non-strikeout. Operational usefulness
has not been established. The learning task remains probability forecasting.

## Verification

All 16 submitted files are preserved. All 15 recorded input hashes match their
archived inputs. Cohort IDs, Train-only behavior coefficients, all 446 probabilities,
pooled/per-game scores, fixed calibration bins and the selection rule were
independently checked. Independent logistic IRLS reproduced predictions to within
approximately 2.1e-13. RDS objects were retained intact but not deserialized in
this environment. No Test performance was calculated during the review.

## Final protocol: unchanged selection, additional fitting data

1. Retain the selected formula: `target_strikeout ~ log_routine + total_tics`,
   with `log_routine = log(routine_time_secs)` and a binomial logit model.
2. Refit on Train plus Validation: 1,250 PAs, 33 games, 218 strikeouts.
3. Re-estimate the constant comparator from these same fitting rows:
   218/1,250 = 0.1744. Do not estimate it from Test prevalence.
4. Freeze both fitted models before scoring Test.
5. Evaluate both on 208 Test PAs from six later games. Primary metric is log loss;
   Brier, ROC-AUC, per-game results, fixed calibration bins and .5-threshold
   confusion counts are descriptive diagnostics.
6. Report what happens, including any failure to beat the baseline. There is no
   model reselection, feature engineering, recalibration or threshold search
   using Test results. Reproducing the identical fixed evaluation is not a new
   independent test. Further model development would need fresh evaluation data.

Refitting changes coefficient estimates and the baseline probability, as planned.
It does not change the selected model's features or family. Validation scores
served selection and are not the final unbiased performance claim. Six test
games will still support only a limited assessment for this team's recorded
period. No independent-PA performance intervals or hypothesis tests are promised.
Earlier full-period predictor EDA remains documented; the procedure does not
retroactively make those predictor distributions unseen.

Prediction timing remains after the first-pitch routine and before its pitch
outcome, restricted to eligible observed-duration/tic records. These models do
not evaluate all teams, unseen players in general, or later-pitch snapshots.

## Run instructions

Merge `scripts`, `docs`, and `outputs` into the working GitHub repository. Run:

```r
source("scripts/13_project3_final_test.R")
```

No new packages are needed. It first verifies previous hashes, stores the final
fitted model and plan, then performs Test evaluation. It writes a timestamped
folder under `outputs/project3/final_test/`, including:

- final coefficients and frozen fitted model;
- test probabilities, metrics, comparator differences and per-game results;
- ROC points, fixed calibration table and a PNG diagnostic figure;
- an automatically generated test-output summary pending interpretation;
- cohort IDs, input hashes, session information and interpretation limits.

Send the entire new folder as a ZIP, including warnings.txt if generated. Script
13 has been inspected, but has not been run in R in the review environment.
Test identifiers/dates/predictor completeness were structurally checked without
inspecting Test target values or calculating their performance.

Suggested commit after execution:
`Evaluate frozen behavior model on the reserved test period`

Push origin while retaining private visibility. After review we will prepare
the Workstream 3 research summary and begin the game-level Workstream 4. No
remote repository changes were performed by the assistant.

## @Ilias' projects

No updates in this checkpoint.
