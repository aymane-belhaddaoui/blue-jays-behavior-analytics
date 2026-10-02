# Workstream 3 — Final test output

Interpretation pending review. Model selection is closed.

| Model | Log loss | Brier | ROC-AUC | Accuracy at .5 | Recall at .5 |
|---|---:|---:|---:|---:|---:|
| M0_prevalence | 0.475687 | 0.149385 | 0.500 | 0.817 | 0.000 |
| M2_behavior | 0.480090 | 0.150350 | 0.541 | 0.817 | 0.000 |

![Final test diagnostics](final_test_diagnostics.png)

Test has now been evaluated; it is no longer unused for this project.
M2 remains the validation-selected approach; do not select a replacement using these test scores.
If M2 loses to prevalence, report failure to beat that benchmark on these six games.
All performance numbers are descriptive; six game clusters limit uncertainty assessment and generalization.
No independent-PA confidence intervals or formal model-comparison p-values are claimed.
Threshold .5 is a diagnostic convention, not an optimized operational threshold.
Calibration displays do not authorize post-test recalibration. New development would require fresh evaluation data.
Earlier full-period predictor EDA was documented; held-out target evaluation followed the frozen selection sequence.
Prediction time is after the first-pitch routine, before the first-pitch outcome.
The final model concerns eligible observed-routine/tic PAs in this team/time window, not all baseball PAs.
GitHub remains private until all four workstreams are finished.
