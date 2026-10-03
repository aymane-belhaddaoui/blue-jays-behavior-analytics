# Pre-pitch behavior and game outcomes: four-workstream synthesis

Analytical close: October 3, 2026. All four initial workstreams are complete within their documented scope. Final report presentation and repository publication preparation remain.

## Project question

How do recorded pre-pitch routines and tic counts vary with game context, how much can be learned about disruptions and outcomes, and do these measurements improve prediction on later games?

The Management Engineering perspective is to examine measured process variation, preserve observation timing, quantify uncertainty appropriately, and distinguish descriptive patterns from predictive usefulness. The dataset supports a bounded observational study rather than a claim about all teams or seasons.

## Data foundation

The supplied log contains 39 games, 17 batters, 1,461 plate appearances, and 5,634 pitches. Four core tables preserve the Game → PA → Pitch relationship and the batter dimension. Four project tables expose task-specific analytical grains. SQL Server supports relational validation; R supports diagnostics and modeling; Power BI presents game-level results and history.

The user's provenance declaration is that available measurements were observed or calculated, with none extrapolated. The one calculated routine, three missing routine measurements, disputed sequence, and inferred outcome remain identified rather than being silently promoted to observed facts. Eligibility rules differ by outcome and workstream. In particular, the calculated duration does not invalidate separately observed tic counts.

## Results across the four workstreams

| Workstream | Question and method | Main result | What can be concluded |
|---|---|---|---|
| 1. Context and behavior | Train-only pitch-level linear mean contrasts, batter/game fixed effects, game-clustered CR2 inference | RISP routine contrast +0.698 s, nominal 95% CI 0.281–1.116; tic contrast +0.111, CI 0.028–0.193 | Modest adjusted behavioral associations in the development sample |
| 2. Disruption and PA outcome | First-pitch exposure audit, unadjusted logistic model, sparse-table reference and omitted-game support | Only 13 exposed PAs and one exposed strikeout; sample OR 0.376; independent-PA Fisher interval approximately 0.009–2.575 | Too little exposure/event support for a stable richly adjusted effect estimate |
| 3. First-pitch prediction | Expanding chronological development folds, fixed candidate round, validation selection, final later-period assessment | Selected behavior model test log loss 0.480090 versus prevalence 0.475687; Brier also worse; AUC 0.541 | No demonstrated probability-score improvement over the benchmark on the six test games |
| 4. Game-level patterns and BI | Equal-game-weight summaries, rolling history, six descriptive correlations, Power BI QA | Prior-five-game win rate versus routine mean: r = 0.499, rho = 0.522 across 34 games; prior-streak/tic association near zero | A context-specific descriptive pattern, without causal or forecasting proof |

## A coherent conclusion

In this dataset, behavior varies with context, but the selected behavioral model did not improve held-out strikeout probability estimates over a prevalence baseline. The two findings concern different questions and can coexist. A statistically detectable adjusted mean contrast does not automatically produce a useful classifier, and a descriptive game-level correlation does not establish an intervention effect.

Workstream 2's sparse exposure support is itself an analytical finding. It constrains what the dataset can answer. Reporting the boundary honestly is more defensible than fitting a large model around one exposed event.

Workstream 4 also shows that “recent success” must be defined. Prior-five-game win rate and consecutive-win streak are different historical summaries, with different supports and associations. Neither is a direct measurement of confidence or psychological momentum.

## Decision implications

The current study supports using the dashboard to inspect measured process variation and trace observations by game, venue, and opponent. It does not support prescribing shorter routines or fewer tics to improve outcomes. For further study, the main evidence needs are more games, more consistently observed disruption exposures, and detailed context that can address lineup and opponent composition.

The existing Workstream 3 test is used and its selection cycle is closed. Additional model development would require new evaluation data. No model is retrospectively selected because it looks better in Workstream 4.

## Important boundaries for the public narrative

- RISP is an observed context, not a direct stress measurement. “Tics” denotes the recorded behavior-count fields, not a clinical diagnosis.
- Workstream 1 estimates and intervals are exploratory and nominal. Game clustering does not remove arbitrary across-game dependence.
- Workstream 2's Fisher calculation is an independent-PA reference, not game-clustered adjusted inference. A wide interval is not proof of equivalence or absence of an effect.
- Workstream 3 used 1,027 Train PAs, 223 Validation PAs, and 208 Test PAs. Earlier full-period predictor EDA was documented. The final test had six game clusters.
- At a 0.5 classification threshold, both final models had 81.73% accuracy and zero strikeout recall. Accuracy must not be promoted as a model success.
- Workstream 4 correlations are unadjusted and descriptive. Overlapping history windows and repeated team observations limit independent evidence.

## Reviewed reports

- [Workstream 1](../workstream1/WORKSTREAM1_RESEARCH_SUMMARY.md)
- [Workstream 2](../workstream2/WORKSTREAM2_RESEARCH_SUMMARY.md)
- [Workstream 3](../workstream3/WORKSTREAM3_RESEARCH_SUMMARY.md)
- [Workstream 4](../workstream4/WORKSTREAM4_RESEARCH_SUMMARY.md)

The earlier reports retain their dated stage-specific context. This synthesis and the final checkpoint record the current overall project status. Immutable run folders preserve the code, output tables, figures, hashes, and session information underlying the reports.
