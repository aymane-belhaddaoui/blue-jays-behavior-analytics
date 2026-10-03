# Finish the Workstream 4 analysis and report presentation

The submitted Power BI numerical checkpoint passed. You can proceed with the final descriptive analysis while making the report refinements below. This package adds script 17 and preserves the submitted screenshots and QA tables.

## 1. Keep the game-weighted cards and clarify their labels

The current `Mean Game Routine Seconds` card correctly displays 14.19. It is the equal-weight average of the 39 game means. The pitch-weighted measure would display 14.24; that is a different quantity. Retain the game-weighted cards because this page concerns game-level patterns.

Use these visible labels:

| Card | Use this existing measure | Visible label |
|---|---|---|
| Games | `[Games]` | Games |
| Currently “Sum of win” | `[Wins]` | Wins |
| Currently “Sum of run_diff…” | `[Run Differential]` | Run differential |
| Win Rate | `[Win Rate]` | Win rate |
| Mean Game Routine Seconds | `[Mean Game Routine Seconds]` | Mean routine duration (s) |
| Mean Game Tics | `[Mean Game Tics]` | Mean tic count |

Replace the two automatically summed fields with their existing calculator-icon measures. The numbers should remain 20 and 15. Add a brief note below the behavioral cards: **Behavioral summaries give each game equal weight.** Use two decimals for the behavioral cards. No new DAX calculation is needed.

## 2. Use straight lines and game markers

The screenshots show curved interpolation. It does not change the exported values, but it draws a smooth trajectory between discrete games.

For each chart, select the visual and open **Format visual → Lines → Interpolation → Straight**. Under **Markers**, turn markers on for the individual-game routine series and the prior-five-game win-rate series. The trailing-five routine mean can remain a plain straight line. Keep game_order ascending on the X-axis.

## 3. Format the historical win rate as a percentage

Select `[Prior 5 Win Rate]` in the Data pane and set its model format to Percentage with zero decimal places. Keep the chart's numeric Y-axis range at 0 to 1: the displayed labels should become 0% to 100%. Do not multiply the underlying measure by 100. Its value 0.6 means 60%.

The header card's Win Rate of 51.28% is already formatted correctly. If a chart retains fractional labels, inspect and remove a conflicting visual-level format override.

## 4. Give the game table its own readable page

The current detail table is cramped and horizontally scrolled. Move it to a full-width page named **Game details**. On this page, show:

`game_order`, `game_id`, `game_date`, `opponent`, `venue`, `result`, `[Runs For]`, `[Runs Against]`, `[Mean Game Routine Seconds]`, `[Mean Game Tics]`, `[Prior 5 Win Rate]`.

Set the game-order column to **Don't summarize**, display a short date, and sort by game_order ascending. Keep game_id visible: the September 23 and September 27 doubleheaders each need two identifiable rows. The QA file already preserves them correctly; the screenshot alone does not show the unique IDs.

The overview page can then use its available width for cards, slicers, and charts. Change the bottom methodological note from bold red to ordinary dark gray, and allow it to wrap. Retain its definitions. An appropriate page title is **Blue Jays game overview — 14 August–27 September 2026**.

These are presentation changes. The reviewed numerical results do not require correction.

## 5. Run the final descriptive analysis in RStudio

Merge this package's contents into the existing repository root, then run:

```r
source("scripts/17_project4_game_associations.R")
```

The script uses base R and the reviewed game export. Its source-data checks and numerical references were inspected independently in Python; it has not been executed in R in this review environment.

The six fixed exploratory comparisons pair each of the two behavioral means with each context:

| Context | Game cohort | Comparisons |
|---|---:|---|
| Same-game win/loss | 39 games | Routine mean and tic mean |
| Win rate in five preceding logged games | 34 games | Routine mean and tic mean |
| Prior win streak after an observed loss reset | 36 games | Routine mean and tic mean |

The first five games lack a full five-game history. For streaks, the first three pregame runs may extend before the observation window. The primary comparison starts after the first recorded loss, at game 4. All 39 source rows and their original window-defined streak values remain unchanged; a separate sensitivity includes all 39.

Pearson correlation measures linear association. With binary win/loss, it is the point-biserial correlation. Spearman correlation applies the same idea to average ranks, retaining ties. Both describe associations among the game summaries; neither estimates a causal effect.

The script also removes one game at a time to show how much individual games influence each coefficient. It keeps the other games' recorded historical context fixed. These ranges are influence diagnostics, not confidence intervals. There are no hypothesis-test p-values: this small observational series includes serial dependence and overlapping history windows.

Outputs include the six correlations, pair membership, all leave-one-out results, context-group counts, boundary sensitivity, win/loss contrasts, a six-panel figure, an analytical draft report, source script, input hashes, session information, and RDS. All six comparisons remain in the report regardless of coefficient magnitude.

## 6. Return the final-analysis checkpoint

1. ZIP the complete newly created timestamped folder under `outputs/project4/associations/` and upload it.
2. Send updated screenshots of **Game overview** and **Game details**. Save the revised PBIX inside the repository.
3. Include the saved-model QA result for the Yankees-filtered rolling history if convenient: run the existing script 16, choose result 7, and save it as `qa_yankees_rolling.tsv`. This checks the stated history behavior under an opponent filter, which was not part of the three tables submitted so far.

The next review will validate the R run and finish the Workstream 4 interpretation. The four-workstream portfolio synthesis follows. Keep the GitHub repository private through completion. Suggested checkpoint commit: `Verify Power BI outputs and add final game association analysis`.

## Power BI references

- [Line interpolation and markers](https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-line-chart)
- [Model and visual number formats](https://learn.microsoft.com/en-us/power-bi/create-reports/desktop-custom-format-strings)
