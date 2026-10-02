# Workstream 3 — Initial prediction design

## @Aymane's projects

GitHub remains private until all four workstreams are finished. Workstream 1's
initial exploratory summary is complete; Workstream 2's initial strikeout
analysis is reviewed and documented with evidence limits. Workstream 3 begins
with prediction benchmarks; Workstream 4 remains pending.

### Task and prediction time

Predict the final PA strikeout indicator after the first-pitch routine has been
observed and before the first-pitch outcome is known. This is not a pre-routine
forecast. Use one first-pitch row per eligible PA. Target: target_strikeout.
The training cohort has 1,027 rows and 185 strikeouts. Counts and pitch number
are constant at the first pitch and are excluded. Alternative target_pa_group,
PA outcome, full-PA aggregates, game ID, date and row IDs are not predictors.
Only RISP, home/road and inning are joined by the unique pitch ID as initial context.
Behavior consists of log(duration) and total tics. Log duration is specified
before evaluating predictive results and requires strictly positive durations.

These benchmarks estimate prediction for later games of the recorded team;
they do not demonstrate transportability to new players or teams. Batter ID is
retained only for audits in this step. A richer player/context benchmark remains
necessary before claiming behavior adds information beyond player identity.

### Four fixed benchmarks

- M0_prevalence: probability equal to strikeout prevalence in the fitting window.
- M1_context: logistic model with RISP, home/road and linear inning.
- M2_behavior: logistic model with log routine duration and total tics.
- M3_context_behavior: logistic model combining those five predictors.

No class balancing, imputation, predictor selection, probability calibration or
threshold optimization is performed. These are intentionally simple starting
benchmarks. R base glm is sufficient; no new package is needed.

### Chronological assessment within Train

Whole game dates remain together in fixed expanding windows:

| Fold | Fit dates | Fit PAs | Assess dates | Assess PAs |
|---|---|---:|---|---:|
| 1 | Aug 14–27 | 451 | Aug 28–Sep 2 | 187 |
| 2 | Aug 14–Sep 2 | 638 | Sep 3–7 | 201 |
| 3 | Aug 14–Sep 7 | 839 | Sep 8–13 | 188 |

All dates are 2026. Assessment covers 576 distinct PAs in the last 15 training
games. The first 12 games initialize fitting. Later folds may fit on earlier
assessment dates, as information becomes available chronologically; each PA
gets one assessment prediction per model. This is not random K-fold resampling.
The separate Validation and Test periods are not evaluated at this stage.
Earlier full-period predictor EDA remains documented and is not relabeled unseen.

Primary comparison: log loss (lower is better). Secondary: Brier score (lower
is better). ROC-AUC describes ranking. Precision, recall, confusion counts and
accuracy at 0.5 are diagnostics, not optimized operating points. Precision is NA
when no positives are predicted. About 82% training accuracy is possible by
always predicting non-strikeout, so accuracy alone cannot establish usefulness.
The constant-probability benchmark is estimated afresh from each fit window.
Inspect fold results alongside pooled values; pooled AUC can reflect changes
between folds. These estimates have no independent-PA uncertainty intervals or
formal model-comparison p-values attached. The three fits share training data.

A better development score does not finalize the model. Review temporal stability,
then decide the next candidate set before validation. Keep Test for one final
assessment after model and operating choices are frozen. Do not increase model
complexity merely to turn an unhelpful signal into a favorable result.

### Run and commit

Merge this ZIP's scripts, docs, deliverables and outputs folders into the working
GitHub repository. Run:

`source("scripts/10_project3_baselines.R")`

Upload the new `outputs/project3/baselines/<timestamp>/` folder as a ZIP. Include
warnings.txt if generated. Source was inspected and joins/fold separation/design
matrix rank were checked in Python, but the R script has not been run here.
No predictive performance result is claimed yet.

Suggested commit: `Document Workstream 2 and add temporal prediction baselines`.
Push origin, retaining private visibility. The checked association run and review
notes are included for the repository's audit trail; no remote edits were made.

References:
- https://rsample.tidymodels.org/articles/Common_Patterns.html
- https://www.stat.ethz.ch/R-manual/R-devel/library/stats/html/predict.glm.html

## @Ilias' projects

No updates in this checkpoint.
