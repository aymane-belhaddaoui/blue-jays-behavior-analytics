# Workstream 4 — Game-level behavior, outcomes, and recent history

Analytical review completed on October 3, 2026. The descriptive analysis is complete. The Power BI numerical checkpoint passed; final presentation corrections are listed in the publication handoff.

## Main conclusion

Across these logged games, the clearest of the six examined associations was a positive relationship between the preceding five-game win rate and current-game mean routine duration: Pearson r = 0.499 and Spearman rho = 0.522, using 34 games with complete prior history. This is an unadjusted exploratory association. It does not establish psychological momentum, a causal effect of recent wins, or a benefit from changing routine duration.

Winning games also had lower mean tic counts than losing games, with Pearson r = -0.307. The association between prior win streak and tic count was close to zero, and its Pearson sign changed when some individual games were omitted. The analysis does not support one general claim that all behavioral measures move together with all definitions of recent success.

## Data and analytical grain

The source covers 39 logged games from August 14 through September 27, 2026: 20 wins, 19 losses, 18 home games, 21 road games, and 10 opponents. All 5,634 source pitch rows remain in the Power BI fact table. Analytical means use observed measurements from valid PA sequences and exclude pitcher-disrupted pitches: 5,553 routine observations and 5,554 tic observations. The calculated routine, missing measurements, and disputed sequence records remain traceable in the source data.

Each observation in this workstream's correlations is one game, with equal game weight. The outcome summaries are each game's eligible routine mean or tic mean. The overall mean of game routine means is 14.190768 seconds, whereas the mean across all eligible pitches is 14.241851 seconds. These answer different weighting questions. The overview page uses game-weighted summaries consistently with the macro-level analysis.

The 39 games are not necessarily independent statistical replications. They concern one team over a short period, with repeated players, chronological dependence, and overlapping historical windows.

## Six exploratory comparisons

The six-comparison plan followed earlier EDA; it is not described as preregistered or confirmatory. Both Pearson and Spearman coefficients are reported for every pair.

| Context | Behavioral game mean | Games | Pearson r | Spearman rho |
|---|---|---:|---:|---:|
| Same-game win/loss, win = 1 | Routine duration | 39 | -0.134 | -0.178 |
| Same-game win/loss, win = 1 | Tic count | 39 | -0.307 | -0.283 |
| Prior-five-game win rate | Routine duration | 34 | 0.499 | 0.522 |
| Prior-five-game win rate | Tic count | 34 | 0.110 | 0.134 |
| Prior win streak after an observed reset | Routine duration | 36 | 0.152 | 0.150 |
| Prior win streak after an observed reset | Tic count | 36 | 0.027 | 0.060 |

Pearson r measures linear association; with a binary win indicator, it is the point-biserial correlation. Spearman rho correlates average ranks and retains ties. Neither coefficient estimates an adjusted or causal effect. No p-values or confidence intervals are reported for these descriptive game-level correlations.

Same-game win status and full-game behavior are retrospective. This comparison is not a pregame forecasting assessment. Prior history precedes current-game behavior, but temporal ordering alone does not remove confounding by lineup, opponent, venue, chronology, or other context.

## History definitions and support

Prior-five-game win rate uses the five preceding logged games and excludes the current game. The first five games have no complete history and remain blank for this measure, yielding 34 eligible games. Doubleheaders occupy separate game_order positions.

For the primary streak analysis, a preceding loss must have been observed within the window, so that the start of the subsequent recorded win run is known. The first observed loss is game 3; the primary analysis starts at game 4 and contains 36 games. The first three window-defined streak counts are preserved and included in a separate all-39-game sensitivity.

| Prior win streak | Primary-cohort games |
|---:|---:|
| 0 | 19 |
| 1 | 11 |
| 2 | 3 |
| 3 | 2 |
| 4 | 1 |

Longer streaks have very little support. The point at a streak of four comes from one game and cannot establish a stable subgroup pattern.

Including all 39 window-truncated streak values gives Pearson r = 0.189 for routine duration and 0.056 for tics, versus 0.152 and 0.027 in the primary 36-game cohort. Corresponding Spearman values are 0.210 and 0.118, versus 0.150 and 0.060. This sensitivity does not establish a strong streak-behavior relationship.

## Win/loss contrasts

| Measure, equal game weights | Winning games, n = 20 | Losing games, n = 19 | Win minus loss |
|---|---:|---:|---:|
| Mean routine duration, seconds | 14.0614 | 14.3269 | -0.2655 |
| Mean tic count | 1.3676 | 1.4941 | -0.1264 |

These are unadjusted differences between game summaries. They do not imply that shortening a routine or reducing tic counts would increase the probability of winning. They also do not estimate the within-batter RISP contrast examined in Workstream 1.

## Single-game influence

| Pair | Full-cohort Pearson r | Leave-one-game-out minimum | Maximum |
|---|---:|---:|---:|
| Win/loss — routine | -0.134 | -0.201 | -0.084 |
| Win/loss — tics | -0.307 | -0.361 | -0.271 |
| Prior-five win rate — routine | 0.499 | 0.462 | 0.538 |
| Prior-five win rate — tics | 0.110 | 0.006 | 0.227 |
| Prior streak — routine | 0.152 | 0.115 | 0.214 |
| Prior streak — tics | 0.027 | -0.022 | 0.094 |

The prior-five-win-rate/routine coefficient remains positive after every single-game omission. That shows it is not driven entirely by one row. It does not demonstrate robustness to removing a chronological block, adjusting for confounders, or collecting new games. These ranges are influence diagnostics, not confidence intervals or independent replications.

Historical exposure values stay fixed for the remaining rows during each omission. The calculation removes an observation from the correlation; it does not rewrite the recorded game sequence or recompute a counterfactual history.

![Game-level associations](game_associations.png)

## Power BI implementation

The compact model links a 39-row DimGame and a 17-row DimBatter to the 5,634-row FactPitch through single-direction one-to-many relationships. Game results are summarized from game rows, while eligible pitch means use explicit measurement flags. Separate measures distinguish pitch-weighted and game-weighted means.

The submitted QA exports match all 17 overall measures, both venue rows, and all 39 individual-game rows, including the intended blank historical values. The largest difference from independent references was approximately 3.91e-14. The relationship screenshot shows the intended structure, and venue QA supports game-to-pitch filtering. No PBIX/model-definition export or exhaustive opponent/batter filter tests were supplied.

The updated overview correctly displays straight lines, game markers, percentage labels, explicit Wins/Run Differential card labels, and valid game-weighted behavioral values. The game-detail screenshot preserves distinct IDs and chronological order. Its remaining corrections are to stop summing game_order, improve text size, and show routine duration alongside tics. Screenshots are preserved as submitted; no claim is made that the assistant edited the PBIX.

![Game overview submitted October 3](overview.png)

## Reproducibility and verification

Final R run: `outputs/project4/associations/20261003_194642_19800/`.

All 13 recorded input hashes match the archived inputs, and the executed script matches the prepared version. Independent Python calculations reproduced all six correlations, 218 pair-data rows, 218 leave-one-game-out rows, 22 context-support rows, 39 history-eligibility rows, four streak-boundary sensitivity rows, and both win/loss contrasts. The six-panel figure and updated dashboard screenshots were visually reviewed.

All 18 original R-run files and both screenshots are archived unchanged. The user's R run provides the execution record; the review environment used Python for independent checks and preserved the RDS without deserializing it. The original machine-generated draft remains inside the run folder. This reviewed report supplies the final interpretation.

The analytical scope of Workstream 4 is complete. Its descriptive results complement the pitch-level associations and the limited predictive performance reported in Workstreams 1–3. Additional data and an explicit design would be needed to establish transportable prediction or causal mechanisms.
