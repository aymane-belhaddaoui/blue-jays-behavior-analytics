# Pre-Pitch Behavior and Game Outcomes

An observational baseball analytics portfolio connecting relational data engineering, statistical inference, chronological prediction evaluation, and Power BI reporting.

**Status:** all four initial analytical workstreams are complete. Final dashboard presentation and public-release preparation are in progress.

## Overview

This project studies recorded Toronto Blue Jays pre-pitch behavior across 39 logged games in August–September 2026. It asks how routine duration and tic counts vary with context, whether disruptions can be linked reliably to plate-appearance outcomes, and whether first-pitch behavior improves strikeout prediction on later games.

The Management Engineering motivation is to connect process measurement and variation with defensible decisions. The study preserves sparse-data limitations and an unsuccessful predictive benchmark comparison as part of its findings.

## Main findings

| Workstream | Result |
|---|---|
| Context and behavior | After batter/game adjustment, RISP was associated with +0.698 seconds of routine duration and +0.111 recorded tics per pitch in the training cohort. |
| Disruption and strikeout | Only 13 training PAs had first-pitch disruption, including one strikeout. The sample was too sparse to support a reliable richly adjusted association estimate. |
| First-pitch prediction | The validation-selected behavior model did not beat prevalence on final test log loss: 0.480090 versus 0.475687. Brier score was also worse; test ROC-AUC was 0.541. |
| Game-level patterns | Prior-five-game win rate and current-game routine mean had descriptive Pearson r = 0.499 across 34 games. This does not establish causal momentum or a forecasting benefit. |

**The central finding:** contextual behavioral associations did not translate into a demonstrated improvement in later-period strikeout probability prediction with the selected model.

Read the [four-workstream synthesis](deliverables/portfolio/FOUR_WORKSTREAMS_SYNTHESIS.md) for interpretation and boundaries.

## Data and provenance

| Grain | Records |
|---|---:|
| Games | 39 |
| Batters | 17 |
| Plate appearances | 1,461 |
| Pitches | 5,634 |

The core tables are `games`, `batters`, `plate_appearances`, and `pitches`. Four project-specific tables support the analytical tasks. The supplied measurements are declared observed or calculated, with none extrapolated. Calculated/missing values and sequence/outcome corrections remain flagged; eligibility rules select the appropriate cohort for each question. The database's provenance and data dictionary document these distinctions.

Analytical missing values were not replaced with zeros, and long observations were not discarded solely for being extreme. Three routine measurements remain missing. One calculated routine is excluded from observed-routine analyses while its separately observed tic count can remain eligible.

## Methods and tools

- **SQL Server / T-SQL:** relational tables, grain checks, joins, and analytical extracts.
- **R:** cohort diagnostics, linear models with game-clustered CR2 inference, logistic models, chronological validation, ridge and random-forest candidates, and descriptive game-level associations.
- **Power BI:** explicit DAX measures, game/pitch filtering, five-game history, and numerical reconciliation against R-derived references.
- **Git/GitHub:** versioned source, immutable run folders, input hashes, session records, and research reports.

Independent Python checks were used to reconcile exported data and numerical results. Their scope and engine limitations are recorded in the review files.

## Evaluation design

The prediction cohort contains one eligible first-pitch snapshot per PA. Train has 1,027 PAs across 27 games; Validation has 223 across six games; Test has 208 across six later games. Prediction time is after the first-pitch routine is observed and before the pitch outcome.

Candidate development used expanding chronological folds within Train. A fixed shortlist was selected by validation log loss. The selected model was refitted on Train plus Validation, then assessed once under the recorded final-test protocol. The Test is now used, and model selection is closed. Earlier predictor EDA across all dates is documented.

## Power BI preview

![Game overview](deliverables/workstream4/overview.png)

The behavioral cards give each game equal weight. The model also contains separately named pitch-weighted measures. Rolling windows use logged game order, preserving doubleheaders; prior-five windows exclude the current game, and trailing-five windows include it.

## Reports

- [Workstream 1: RISP and behavior](deliverables/workstream1/WORKSTREAM1_RESEARCH_SUMMARY.md)
- [Workstream 2: disruption and strikeout](deliverables/workstream2/WORKSTREAM2_RESEARCH_SUMMARY.md)
- [Workstream 3: first-pitch prediction](deliverables/workstream3/WORKSTREAM3_RESEARCH_SUMMARY.md)
- [Workstream 4: game-level patterns](deliverables/workstream4/WORKSTREAM4_RESEARCH_SUMMARY.md)

## Repository structure

| Folder | Contents |
|---|---|
| `data/` | Core relational and project CSVs |
| `metadata/` | Schema, data dictionary, provenance, and validation records |
| `scripts/` | SQL, numbered R stages, and DAX definitions/checks |
| `outputs/` | Timestamped run artifacts and submitted Power BI QA records |
| `deliverables/` | Reviewed reports, tables, figures, and dashboard materials |
| `docs/` | Review checkpoints, verification records, and workflow instructions |

## Reproduction

Use the repository root as the R working directory. Start with `scripts/01_import_R.R`. The recorded analysis stages use saved inputs from the archived run folders; inspect each script's default paths and its `input_hashes.csv` dependency record. Package versions are recorded in each run's `sessionInfo.txt`.

For Power BI, import the three files from `outputs/project4/game_kpis/20261002_214708_23628/powerbi/` and follow `docs/POWERBI_BUILD_GUIDE.md`. Scripts 15 and 16 contain the DAX measures and QA queries. The submitted overall, venue, and game exports reconcile with independent numerical references.

This repository records reproducible individual stages using archived inputs. A single fresh end-to-end automation command has not been validated. The final checkpoint records which local authoring files and presentation items remain to be placed in the release.

## Limitations

This is an observational study of one short team-specific window. RISP is not a direct measure of stress, and the recorded tic variables are not clinical measures. Workstream 1 inference assumes independent game clusters; Workstream 2's sparse-table uncertainty uses an independent-PA reference; Workstream 4 correlations are descriptive and unadjusted. None establishes a causal intervention effect.

The selected prediction model did not demonstrate superiority to prevalence on the six test games. Its 81.73% accuracy at a 0.5 threshold came with zero strikeout recall and is not evidence of a useful classifier. Further predictive development would require fresh evaluation data.
