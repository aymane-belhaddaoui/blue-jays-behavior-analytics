# Power BI checkpoint review — 2026-10-03

Submitted archive: `powerbi.zip`, containing two PNG screenshots and three TSV exports. All five originals are preserved unchanged under `outputs/project4/powerbi_qa/20261003_review/`.

## Numerical review

| Export | Scope | Result |
|---|---|---|
| qa_overall.tsv | 17 overall measures | Matches every reference value |
| qa_venue.tsv | Home/road groups, 17 measures each | Matches within floating-point rounding |
| qa_game.tsv | All 39 games and their history measures | Matches within floating-point rounding; 18 intended blank cells preserved |

The largest absolute numeric difference from the independent references was approximately 3.91e-14. Date strings were normalized to calendar dates for comparison; no date values changed. Both doubleheaders remain distinct by game_id and game_order.

The model screenshot shows two solid one-to-many relationships with single-direction arrows from DimGame and DimBatter toward FactPitch. The supplied venue results numerically support game-to-pitch filtering. The exact relationship key settings are not fully visible, and no PBIX/model-definition export was supplied. Batter-filter and opponent-filter QA tables were not included; this review does not claim exhaustive verification of every filter context.

## Presentation findings

The 14.19-second and 1.43-tic cards are valid equal-game-weight summaries. Retain this design choice and label its weighting. Replace automatic “Sum of…” labels with the existing explicit measures. Use straight interpolation and visible game markers, display historical win rates as percentages, and put the detailed game table on a readable full-width page with game IDs visible.

These refinements do not correct a data or formula discrepancy; the submitted values are correct. Instructions are in `NEXT_STEPS.md`.

## Remaining analysis

Script 17 reports six exploratory correlations between game-level behavioral means and same-game result, prior-five-game win rate, and prior win streak. It includes paired-row membership, context support, Pearson and Spearman coefficients, fixed-context leave-one-game-out influence, and a streak-start boundary sensitivity. This plan follows prior EDA and is not described as preregistered or confirmatory.

The primary streak cohort includes 36 games after an observed loss reset. The original first-three-game window counts remain intact and appear in a named 39-game sensitivity. No new observations are imputed or extrapolated. No model is selected using these correlations, and Workstream 3's completed test remains closed.

## Project status

- Workstreams 1 and 2: reviewed initial analyses and reports retained.
- Workstream 3: final assessment complete; failure to beat prevalence on primary test scoring remains the conclusion.
- Workstream 4: data export and supplied Power BI numerical checkpoint verified. Final descriptive association run, presentation refinements, and final interpretation remain.
- GitHub: remains private by the user's instruction. No remote repository operation was performed during this review.
- Portfolio integration: pending the Workstream 4 conclusion. Earlier code, outputs, limitations, and review checkpoints remain part of the reproducibility record.

Detailed numerical checks and archive SHA-256 hashes are in `PROJECT4_POWERBI_QA_VERIFICATION.json`. The new R script was statically inspected and cross-checked against independently computed Python reference quantities; user-side R execution remains pending.
