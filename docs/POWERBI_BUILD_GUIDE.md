# Workstream 4 — Power BI build guide

The R export `20261002_214708_23628` passed independent review. This session creates the Power BI model, saves its measures, checks their results, and builds an initial overview page. No new R run is required first.

## 1. Merge this package into the repository

Extract the ZIP, then copy the contents of `Workstream4_PowerBI_Kit` into your existing repository root. Merge the `scripts`, `docs`, `deliverables`, and `outputs` folders. The reviewed run is included unchanged; core CSVs are not replaced. Do not nest the package folder inside your project.

Use the existing repository location shown by GitHub Desktop when choosing import and save paths. If you retained an older project folder elsewhere, avoid building a second copy there.

## 2. Import the three reviewed tables

Open a blank report in Power BI Desktop. Use **Home → Get data → Text/CSV**, select a file, and choose **Transform Data** to inspect it. Repeat for the three CSVs below. They are in this repository-relative folder:

`outputs/project4/game_kpis/20261002_214708_23628/powerbi/`

| File | Rename the query/table to | Expected rows | Key |
|---|---|---:|---|
| `dim_game.csv` | `DimGame` | 39 | `game_id` |
| `dim_batter.csv` | `DimBatter` | 17 | `batter_id` |
| `fact_pitch.csv` | `FactPitch` | 5,634 | `pitch_id` |

Use exactly these table names: the supplied DAX refers to them. CSV import creates a local Import model. Confirm comma delimiters and UTF-8 encoding, especially accented batter names. In Power Query, inspect the type icon in each column header. Set the following types before **Close & Apply**:

| Table | Type instructions |
|---|---|
| DimGame | `game_id`, `opponent`, `result`, `split`, `disruption_coverage`, `venue`: Text. `game_date`: Date. All means, SDs, CVs, and rates: Decimal number. Counts, scores, `game_order`, `game_on_date`, `home`, `win`, `logged_offensive_innings`, `window_win_streak_before`: Whole number. |
| DimBatter | Both columns: Text. |
| FactPitch | `pitch_id`, `pa_id`, `game_id`, `batter_id`, `pitch_result`, `routine_source`, `tics_source`, `disruption_source`: Text. `routine_time_secs`: Decimal number. Remaining numeric counts, flags, and indices: Whole number. |

If decimal values generate conversion errors, use **Change Type → Using Locale** with Decimal number and English (United States), because the CSV uses a decimal point. Keep null values null. Never replace early rolling-history blanks with zero. If Power Query introduces an incorrect automatic type step, correct that step or remove it before applying the intended types.

The exported `prior5_routine_undisrupted_mean_secs` and `trailing5_routine_undisrupted_mean_secs` are decimal means. The corresponding win-rate columns are decimals too. A rate is stored as a fraction and formatted as a percentage later.

## 3. Create and inspect the relationships

Go to Model view. Use **Manage relationships → New**, or inspect any relationships already detected during import.

| One side | Many side | Cardinality | Filter direction |
|---|---|---|---|
| `DimGame[game_id]` | `FactPitch[game_id]` | One to many | Single: DimGame → FactPitch |
| `DimBatter[batter_id]` | `FactPitch[batter_id]` | One to many | Single: DimBatter → FactPitch |

Both relationships must be active. There should be no relationship directly between DimGame and DimBatter. A single arrow on each relationship should point toward FactPitch. Do not join by date: doubleheaders have two distinct games on one date.

DimGame contains one record per game, including game results and precomputed game summaries. This compact design lets you calculate wins from 39 rows and behavioral means from the eligible pitch rows. Summing wins after duplicating them across pitches would inflate the result.

## 4. Run and save the measures

1. Open `scripts/15_project4_powerbi_measures.dax` in a text editor and copy its entire contents.
2. In Power BI Desktop, select **DAX query view** on the left. Paste the code into a new query tab.
3. Select **Run** with no partial text selection. Compare its one-row result with `deliverables/workstream4/reference/expected_overall.csv` and the quick table below.
4. Once the values match, select **Update model with changes**. This adds the 22 measures to the model. Running the query alone leaves them scoped to that query; visuals need saved model measures.
5. Check that the measures appear with calculator icons beneath DimGame and FactPitch in the Data pane.

If DAX query view is unavailable in your installed version, you can add the measures individually through **Modeling → New measure**. For each definition, paste `Measure Name = expression` without the leading `MEASURE Table` wrapper, `DEFINE`, or `EVALUATE`. Keep the same measure names. This fallback creates the same model calculations.

| Measure | Expected unfiltered result |
|---|---:|
| Games | 39 |
| Wins | 20 |
| Losses | 19 |
| Win Rate | 0.5128205128 = 51.28% |
| Runs For | 166 |
| Runs Against | 151 |
| Run Differential | 15 |
| Pitch Count | 5,634 |
| Valid Pitch Count | 5,627 |
| Disrupted Valid Pitches | 70 |
| Valid Disruption Rate | 0.0124400213 = 1.2440% |
| Routine Eligible Pitches | 5,553 |
| Mean Routine Seconds | 14.2418512516 |
| Tic Eligible Pitches | 5,554 |
| Mean Tics | 1.4281598848 |
| Mean Game Routine Seconds | 14.1907679077 |
| Mean Game Tics | 1.4292233382 |

The reference values were computed independently from the source rows. DAX has not been executed in the review environment; this local Power BI run is the next verification step. Integer counts must match exactly. Differences below 1e-8 in decimal values are harmless numerical rounding.

## 5. Understand what the measures do

**Filter context** is the subset visible to a measure because of slicers, visual rows, and relationships. A venue selection filters DimGame to those games and then filters FactPitch to their pitches. `CALCULATE` in the behavioral measures adds the relevant eligibility flag to that context. `KEEPFILTERS` preserves the intersection with existing filters.

`Mean Routine Seconds` computes the mean over every eligible pitch in the current context. Each pitch has equal weight. `Mean Game Routine Seconds` averages the stored primary mean for each selected game, giving each game equal weight. They agree for a single game but usually differ across games. The first is the appropriate pitch-level headline; the second matches the R group summaries and the rolling game means.

Primary routine/tic measures require an observed measurement, a valid PA sequence, and no pitcher disruption. Disruption rate uses all valid-PA pitches as its denominator. Do not apply a page-wide `pitcher_disruption = 0` or primary-eligibility filter: that would change the disruption measure's population. Let each measure enforce its own definition.

Game totals and precomputed game summaries do not change under a batter filter, because DimBatter filters only FactPitch. For example, selecting B001 leaves Games at 39 and Wins at 20, while Pitch Count becomes 546 and Mean Routine Seconds becomes approximately 14.617811. This is expected. Keep batter slicers on a separate pitch-analysis page if you add one later.

**Rolling measures** require a single game in the current context. `SELECTEDVALUE` supplies that game's order. `FILTER(ALL(DimGame), ...)` retrieves its five neighbors from the full logged chronology. `AVERAGEX` averages the chosen game-level values. The historical window stays the same when you select an opponent or venue; it is not rebuilt from only the visible opponent/venue games.

- Prior 5 excludes the current game and starts at game 6.
- Trailing 5 includes the current game and starts at game 5.
- Both count games, not calendar days. Doubleheaders remain separate.
- History measures intentionally return blank at totals spanning multiple games. Select one game if you want a history card.
- The prior win streak is truncated at the beginning of this observation window; earlier season history is unknown.

## 6. Verify the saved model

Create a second DAX query tab and run all of `scripts/16_project4_powerbi_checks.dax`. It contains no measure definitions, so it checks the saved model measures. Use the **Result** selector to inspect the returned tables.

| Result | Purpose | Reference CSV in `deliverables/workstream4/reference/` |
|---|---|---|
| 1 | Overall totals and means | `expected_overall.csv` |
| 2 | Home/road filtering | `expected_by_venue.csv` |
| 3 | Opponent filtering | `expected_by_opponent.csv` |
| 4 | Win/loss group summaries | `expected_by_result.csv` |
| 5 | All 39 individual game histories | `expected_by_game.csv` |
| 6 | Batter filters affect pitches but preserve game totals | `expected_by_batter.csv` |
| 7 | Yankees selection retains original full-history windows | `expected_yankees_rolling.csv` |
| 8 | No individual game selected | All five history values blank |

These queries specify their own context; report-page slicers do not automatically become filters in a separately executed DAX query. Test the report's slicers separately when building visuals.

Useful boundary checks: game 5 has a blank Prior 5 Win Rate but a Trailing 5 Win Rate of 0.6. Game 6 has a Prior 5 Win Rate of 0.6 and a Prior 5 Mean Routine Seconds of 14.6234162122. Games sharing a date should still occupy distinct rows. An entirely blank result at multi-game totals for a history measure is intended.

Use the result grid's **Copy** control to preserve results 1, 2, and 5 as tab-separated text. Paste each into a plain-text editor and save with UTF-8 encoding as `qa_overall.tsv`, `qa_venue.tsv`, and `qa_games.tsv` under `deliverables/workstream4/powerbi/`. Choose All files when saving so the editor does not append `.txt`. Headers may include table names/brackets; keep them intact.

## 7. Build the first report page

Return to Report view and name the page **Game overview**. Use a 16:9 canvas. Choose a white background with navy text and a consistent blue accent. Formatting should make values and denominators easy to read.

| Visual | Fields/measures | Purpose |
|---|---|---|
| Cards | Games, Wins, Win Rate, Run Differential | Overall game results |
| Cards | Mean Routine Seconds, Mean Tics | Pitch-weighted behavioral summaries |
| Slicers | DimGame `opponent`, `venue`, `game_date` | Filter selected games |
| Line chart | X: DimGame `game_order`; Y: Mean Game Routine Seconds and Trailing 5 Mean Routine Seconds | Routine duration and retrospective five-game mean |
| Line chart | X: DimGame `game_order`; Y: Prior 5 Win Rate | Historical win rate before each game |
| Table | game_id, game_date, opponent, venue, result, runs_for, runs_against, Mean Game Routine Seconds, Prior 5 Win Rate | Inspect individual game values |

Sort both line charts by ascending game_order. Use the numeric order rather than a date hierarchy to preserve doubleheaders. Format counts as whole numbers, routine seconds and tic means to two decimals, and Win Rate to one or two percentage decimals. Set rate charts to 0–100%. Show raw game scores without summing across games in the detail table.

Use titles that retain their definitions: **Routine duration: game means and trailing five games** and **Win rate in five preceding logged games**. Add this short note below the visuals: “Observed routines and tics; valid PA sequences; disrupted pitches excluded from behavioral means. Historical windows follow the full logged game order. Observational results.”

Do not add a batter slicer to this page. First confirm that Home gives 18 games, 11 wins, and 61.11% win rate; Road gives 21 games, nine wins, and 42.86%. Compare the behavioral values too. Reset slicers before saving a default overview screenshot.

## 8. Save and return the checkpoint

Save the report as `deliverables/workstream4/powerbi/Blue_Jays_Game_Overview.pbix` inside the existing repository. Save the two DAX query tabs with it. The separate `.dax` source files make those calculations reviewable in GitHub alongside the binary report.

For the next review, send the three QA TSV files and screenshots of Model view and the unfiltered overview page. Include any exact error text if a query does not run. You can ZIP those files together; the PBIX is optional for this checkpoint. Do not send another R output ZIP for this step.

After the model and overview are verified, we will examine the game-level recent-history associations, finish the analytical report pages, and write the Workstream 4 conclusion. Those steps remain open. Workstream 3's test assessment remains closed. Keep GitHub private until all four workstreams are finished.

## Technical references

- [Microsoft: Text/CSV connector](https://learn.microsoft.com/en-us/power-query/connectors/text-csv)
- [Microsoft: create and manage relationships](https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-create-and-manage-relationships)
- [Microsoft: DAX query view and saving query-defined measures](https://learn.microsoft.com/en-us/power-bi/transform-model/dax-query-view)
- [Microsoft: CALCULATE](https://learn.microsoft.com/en-us/dax/calculate-function-dax)
- [Microsoft: SELECTEDVALUE](https://learn.microsoft.com/en-us/dax/selectedvalue-function-dax)
- [Microsoft: aggregation functions](https://learn.microsoft.com/en-us/dax/aggregation-functions-dax)
- [Microsoft: KEEPFILTERS](https://learn.microsoft.com/en-us/dax/keepfilters-function-dax)
- [Microsoft: ALL](https://learn.microsoft.com/en-us/dax/all-function-dax)
