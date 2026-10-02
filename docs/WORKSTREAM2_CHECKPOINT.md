# Workstream 2 checkpoint — October 2, 2026

## @Aymane's projects

### GitHub decision

The user reports that the repository has been created in GitHub Desktop, the
correct project files copied and the repository published privately. **It will
remain private until all four workstreams are finished.** This supersedes the
earlier suggestion to make it public after Workstream 1. The assistant has not
inspected the remote repository or changed its visibility. GitHub now holds the
working code history; apply this update to that working repository and commit it.

### Completed diagnostics

Run `outputs/project2/diagnostics/20261002_153144_23628` is complete. All 13 files
are preserved. Ten input MD5 hashes match; cohort IDs, exposure/outcome tables,
game/batter support, PA length summaries and pitch-by-pitch timing were checked
against the canonical CSVs. The supplied RDS is intact but was not deserialized.

The cohort has 1,028 training PAs, 27 games, 16 batters and 185 strikeouts.

| First-pitch disruption | PAs | Strikeouts | Observed fraction |
|---|---:|---:|---:|
| No | 1,015 | 184 | 18.13% |
| Yes | 13 | 1 | 7.69% |

First-pitch exposure occurs in nine games and six batters. The one exposed
strikeout is in the August 14 game, for B010. Omitting that game leaves zero
exposed strikeouts: the unadjusted logistic exposure coefficient then has a
boundary maximum likelihood estimate rather than a finite value. This is an
influence/support issue, not a reason to drop that game.

Any-PA disruption occurs in 50 PAs (six strikeouts) versus 978 undisrupted PAs
(179 strikeouts). Among the 50, first disruption is on pitch 1/2/3/4/5/6 in
13/4/8/11/7/7 cases. Thus 37 begin after pitch 1. Fifteen first disruptions are
recorded on the terminal pitch; this does not imply they happened after the
outcome, since the flag is associated with that pitch record. PAs with any
disruption average 5.16 pitches versus 3.7648 without. More pitches permit more
exposure opportunities, so this retrospective comparison does not isolate an
effect of disruption. Total PA length is not a baseline covariate.

Observed zero-disruption dates remain valid observations under the user's earlier
provenance declaration. Do not turn them into missing values or exclude them
because their exposure count is zero.

### Next analysis and its limits

Run `source("scripts/09_project2_sparse_association.R")` from the repository root.
No new packages are needed. It produces:

1. Observed risk difference, risk ratio and sample odds ratio.
2. An exposure-only logistic GLM, with log-odds coefficients, exponentiated
   coefficients and fitted probabilities. This is an unadjusted learning benchmark.
3. Fisher's conditional exact OR interval and two-sided test, explicitly labeled
   an **independent-PA reference**, not clustered or adjusted inference.
4. Leave-one-game-out cell support, flagging zero-event cases without forcing a
   numerically misleading finite logistic estimate.
5. Timestamped CSVs, RDS, session information, input hashes, code and limitations.

The model is `logit(P(strikeout)) = alpha + beta * first_pitch_disruption`.
The hand-calculated sample OR is `(1/12)/(184/831) = 0.37636`; it is not a risk
ratio or adjusted effect. The conditional Fisher OR differs slightly from that
sample OR because it is a different estimator. An independent computation in
Python gives an approximate conditional 95% OR interval [0.00876, 2.57503] and
p=.48297; the user-side R output will be checked before the run is declared
completed. Such an interval allows associations in either direction under that
reference model. It does not prove absence of association or equivalence.

Exact small-cell calculations do not account for dependence among PAs within
batters/games, nor do they control contextual confounding. They are kept as
transparent benchmarks. The primary Workstream 2 conclusion at this stage is
that the sample is too sparse to support a stable, richly adjusted disruption
association. Do not promote the nominal Fisher p-value or the OR below one as
proof that disruption protects against strikeout. Penalization could make an
estimate finite but would not create additional exposure information or remove
confounding. No many-parameter adjusted model is fitted in script09.

This workstream can validly conclude that the available data limit estimation.
After reviewing script09, prepare its brief evidence-limits report and move to
Workstream 3. Do not expand to held-out dates merely to obtain more exposed events.
Workstream 1's completed exploratory research summary remains unchanged.

### Applying and committing this update

Merge the ZIP's `scripts`, `docs`, and `outputs` folders into the repository root.
The included diagnostic outputs match the user's submitted run; preserve any
additional local files. Run script09 in this repository, then send its new
`outputs/project2/association/<timestamp>/` folder as a ZIP for review.

Suggested commit after script09 completes:
`Add Workstream 2 diagnostics and sparse association benchmark`

Push origin in GitHub Desktop, keeping the repository private. The checkpoint
and verification JSON should be committed alongside the script and run outputs.

Method references:
- https://stat.ethz.ch/R-manual/R-patched/library/stats/html/glm.html
- https://www.stat.ethz.ch/R-manual/R-devel/library/stats/html/fisher.test.html

## @Ilias' projects

No updates in this checkpoint.
