# Workstream 4 — Game-level patterns and Power BI

## Question and sequence

Describe how recorded routines, tics, and pitcher disruptions vary across game results, venue, opponent, and recent logged-game history. Use all 39 games. This is an exploratory game-level analysis; same-game behavior becomes known during the game and does not constitute a pregame win forecast.

1. Run script 14 and review its exports, denominators, exclusion audit, chronology, and overview plot.
2. Examine game-level patterns with the game as the outcome unit. Report group sizes and effect magnitudes; overlapping rolling windows and repeated observations of the same team limit independent evidence.
3. Import the reviewed tables into Power BI, define measures, and build the overview, behavioral-pattern, and recent-history pages.
4. Reconcile dashboard totals against the reviewed CSVs, document findings and limitations, save the PBIX, and integrate the four workstreams into the portfolio.

Step 1 is prepared in this package. No PBIX has been created yet.

## Cohorts and denominators

Every source pitch remains in `fact_pitch.csv`. Eligibility flags choose which measurements enter each KPI; they do not delete the underlying record.

| Measure family | Eligibility | Expected pitch count over all games |
|---|---|---:|
| All logged pitches | All source records | 5,634 |
| Valid pitch context | Valid PA sequence | 5,627 |
| Observed routine, disruptions included | Valid PA and observed nonmissing routine | 5,623 |
| Primary routine | Above, with no pitcher disruption | 5,553 |
| Observed tics, disruptions included | Valid PA and observed nonmissing tics | 5,624 |
| Primary tics | Above, with no pitcher disruption | 5,554 |

The seven disputed-PA pitches remain flagged in the fact table. The one calculated routine and three missing routines remain in the source record but do not enter the observed-routine KPIs. A calculated routine can coexist with observed eligible tics. Long observed routines are not trimmed or capped. The exclusion audit can have multiple reasons for a row; do not add reason counts as if they were mutually exclusive.

Valid disruption rate is disrupted valid-PA pitches divided by all valid-PA pitches: 70/5,627 over the full dataset. Valid RISP rate uses that same denominator. Missing values remain blank, not zero. Source game aggregates used broader eligibility rules; they are retained separately as a reference and should not be silently substituted for the new analytical means.

Game means weight eligible pitches equally within each game. Group summaries and rolling means of those game means weight games equally. A dashboard overall mean calculated from eligible fact rows will instead weight pitches equally across games; label the two summaries clearly.

## Import tables and relationships

Only the three files under the reviewed run's `powerbi/` folder are needed for the planned compact model.

| CSV | Power BI table name | Grain | Expected rows |
|---|---|---|---:|
| `dim_game.csv` | `DimGame` | One game, with game attributes, results, and precomputed KPIs | 39 |
| `dim_batter.csv` | `DimBatter` | One batter | 17 |
| `fact_pitch.csv` | `FactPitch` | One pitch, with PA context and eligibility flags | 5,634 |

Create active relationships `DimGame[game_id]` 1:* `FactPitch[game_id]` and `DimBatter[batter_id]` 1:* `FactPitch[batter_id]`. Use single-direction filtering from each dimension to FactPitch. Check the automatically detected relationships rather than accepting a many-to-many join.

For this compact project, DimGame intentionally also carries the game-grain results and summaries. Calculate wins and games from its 39 rows; never duplicate and sum game wins across pitch rows. Calculate interactive pitch-weighted routine/tic means from FactPitch with their eligibility flags.

In Power BI Desktop, import each CSV using **Home → Get data → Text/CSV → Transform Data**. Rename tables as above. Confirm UTF-8 encoding, set IDs/names/categories to Text, `game_date` to Date, flags/counts/order to Whole number, and means/rates/durations to Decimal number. Use the appropriate parsing locale for decimal points if needed. Keep blank rolling values null. Load, then inspect the relationships in Model view. Detailed DAX measures and dashboard construction follow export review.

Batter filtering affects FactPitch measures. It does not change DimGame wins or precomputed game KPIs, because the batter dimension does not filter back through the pitch table. Keep the game-results page free of batter slicers, or make that distinction explicit in titles. Opponent and venue slicers come from DimGame and filter both game summaries and related pitches.

This relationship design follows the dimension/fact filtering concepts in [Microsoft's model guidance](https://learn.microsoft.com/en-us/power-bi/guidance/star-schema); relationship configuration is documented in [Create and manage relationships](https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-create-and-manage-relationships).

## Time and rolling measures

Use `game_order` to order the 39 games, including the two games of each doubleheader. `game_date` is not a unique key. The source's `game_timestamp` has artificial doubleheader offsets and is deliberately omitted from the BI export; it is not an observed start time.

| Field | Window and interpretation |
|---|---|
| `prior5_win_rate` | Five preceding logged games, excludes current game; first five rows blank |
| `prior5_routine_undisrupted_mean_secs` | Equal-weight mean of primary game routine means in those five preceding games |
| `trailing5_win_rate` | Current game plus four preceding games; first four rows blank; retrospective |
| `trailing5_routine_undisrupted_mean_secs` | Equal-weight mean of primary game routine means over that retrospective window |
| `window_win_streak_before` | Consecutive prior wins observed within this dataset, truncated at its beginning |

These precomputed windows stay tied to the full logged chronology. Selecting an opponent displays that opponent's games with their original history; it does not redefine the window to mean the previous five games against that opponent. Later DAX rolling measures must reproduce the same definitions before they are used in the dashboard.

`logged_offensive_innings` measures logged offensive coverage, not complete game duration. Coverage and measurement provenance should remain visible in the final documentation.

## Completion checks

At no filters: 39 games, 20 wins, 19 losses, 18 home games, 21 road games, 10 opponents, 5,634 pitch rows. Primary eligible duration rows: 5,553; tics: 5,554. Confirm a selected game, venue, and opponent against the corresponding CSV totals. Inspect early rolling blanks and doubleheaders. Keep the repository private through completion of all four workstreams.
