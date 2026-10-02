# Workstream 3 — Candidate review and frozen validation plan

Reviewed October 2, 2026, before evaluating the separate Validation outcomes.

## @Aymane's projects

GitHub remains private until all four workstreams finish. Workstreams 1 and 2
have documented initial analyses. Workstream 3's Train-only candidate round is
complete; validation selection comes next. Workstream 4 remains pending.

## Development results

Same 576 assessed PAs, 103 strikeouts, three chronological windows within Train:

| Candidate | Log loss (lower better) | Brier (lower better) | Pooled AUC |
|---|---:|---:|---:|
| M2 behavior logistic | 0.469746 | 0.146584 | 0.531035 |
| M0 prevalence | 0.470701 | 0.147167 | 0.439828 |
| M3 context + behavior logistic | 0.477169 | 0.149116 | 0.485355 |
| M1 context logistic | 0.478147 | 0.149519 | 0.467928 |
| M7 player/context/behavior forest | 0.487730 | 0.150653 | 0.529383 |
| M5 player/context/behavior ridge | 0.490496 | 0.151199 | 0.539769 |
| M6 player/context forest | 0.491077 | 0.151720 | 0.520023 |
| M4 player/context ridge | 0.493880 | 0.152462 | 0.528726 |

M2 remains best on the declared primary metric but its improvement over M0 is
only 0.000955 log loss (about 0.20%). No established practical utility is claimed.
The richer models lose to the prevalence baseline on log loss in each of the
three windows, under these fixed configurations. This does not show that all
possible ridge/forest specifications must fail; it supports ending this bounded
candidate round rather than continuing to search for a favorable result.

Adding behavior improves pooled log loss within both richer model families,
but each family improves in only two of three folds and still loses to baseline.
The higher pooled AUC of M5 does not override the chosen probability-score
criterion. AUC measures ranking; log loss evaluates probability forecasts.
No model-comparison significance result or independent-PA interval is claimed.

At threshold .5, both ridge models predict two positives (one true, one false),
recall 1/103=0.97% and precision 50%. Forests predict no positives, as do the
four initial models. All have the same 82.12% accuracy; this does not demonstrate
useful positive-case identification. We have not chosen an operational threshold.
The constant model's pooled AUC differs from .5 because its constant changes
between folds; each fold's baseline AUC remains .5.

Encoding audits confirm training-only category levels and variance filtering.
Unknown-opponent rows are 187/38/118 and unknown-batter rows 0/8/4 across folds.
All-zero indicators are the documented fallback for unseen levels. Sparse player
information and changing opponents limit what these identity features can learn.
The third forest comparison uses mtry=4 without behavior and 5 with it, under
the fixed square-root rule; do not interpret the difference as a pure causal
feature effect. Full settings and prior selection history remain in the run notes.

## Verification

All 13 candidate-run files are preserved and all 12 input hashes match. Cohort
alignment for all 4,608 saved probability rows was checked. Every fold and pooled
score and the within-family differences were recomputed. The original four
models' predictions agree with the previously reviewed run. Encoded column counts,
unseen categories and settings were checked from training data. The new ridge
and forest models were not independently refitted in R; their RDS is intact but
not deserialized here. Verification of metrics is distinct from model refitting.

## Frozen next step

Shortlist only M0_prevalence and M2_behavior. This decision uses the completed
Train development results, not Validation labels. Existing full-period predictor
EDA stays documented; the study is not retrospectively labeled preregistered.

1. Fit M0 prevalence on all 1,027 Train PAs.
2. Fit M2 `target_strikeout ~ log(routine_time_secs) + total_tics` on the same Train PAs.
3. Predict probabilities for the 223 first-pitch Validation PAs, spanning six games.
4. Select the lower Validation log loss. If the difference is within 1e-12, select M0.
5. Report Brier, AUC, .5-threshold confusion counts, game summaries and fixed
   calibration bins as diagnostics; do not tune from those displays.
6. Review that completed run. Refit the selected model on Train+Validation, then
   assess it on the 208-row Test set once, with prevalence as comparator if M2
   was selected. If M0 was selected, assess M0 only. Do not revisit candidate
   selection in response to test performance.

Validation is used for selection, so its winning score is not the final unbiased
performance claim. Six games provide limited evidence; numerical selection by a
small difference is not proof of meaningful superiority. No threshold optimization,
recalibration, new features or new models are planned after this validation step.
The deliverable remains a probability-prediction study unless an explicit decision
use case and costs justify a later threshold study on new development data.

Script 12 writes the frozen protocol before scoring, then stores model selection,
probabilities, metrics, cohort IDs, fitted model, hashes and session information.
It uses base R, with no additional packages. Test data may be loaded by the shared
ingestion script but are neither predicted nor evaluated. No Validation/Test
scores were computed in this review; script12 has not yet been executed here.

## Apply this update

Merge `scripts`, `docs` and `outputs` into the working repository. Keep the
existing code and past runs; the included candidate folder matches the submitted
run. From the repository root run:

```r
source("scripts/12_project3_validation.R")
```

Send `outputs/project3/validation/<timestamp>/` as a ZIP, including warnings.txt
if generated. After execution, commit with:

`Freeze prediction shortlist and evaluate validation period`

Push origin and keep the repository private. The assistant has not changed the
remote repository or its visibility.

References:
- https://scikit-learn.org/stable/modules/cross_validation.html
- https://scikit-learn.org/stable/modules/generated/sklearn.metrics.log_loss.html

## @Ilias' projects

No updates in this checkpoint.
