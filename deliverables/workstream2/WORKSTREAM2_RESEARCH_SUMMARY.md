# Workstream 2 — First-pitch disruption and strikeout

Initial exploratory strikeout analysis completed October 2, 2026. This is an
observational, unadjusted analysis of 1,028 eligible training plate appearances
from 27 games and 16 batters. It does not cover every possible PA outcome.

## Observed association

| First-pitch disruption | Strikeouts | Other outcomes | Total | Strikeout fraction |
|---|---:|---:|---:|---:|
| Yes | 1 | 12 | 13 | 7.69% |
| No | 184 | 831 | 1,015 | 18.13% |

Observed risk difference: -10.44 percentage points. Risk ratio: 0.4243.
Sample odds ratio: 0.3764. These are different measures; the odds ratio is not
an absolute probability change or a risk ratio.

The exposure-only logistic model is:

`logit(P(strikeout)) = -1.507694 - 0.977213 * first_pitch_disruption`.

Exponentiating the exposure coefficient gives 0.376359, the sample odds ratio.
Exponentiating the intercept gives baseline odds (0.22142), not baseline risk.
The fitted risks reproduce the two observed group proportions. This is expected
for an intercept-plus-binary-exposure model and is not evidence of predictive skill.

## Uncertainty and support

Fisher conditional OR: 0.376614; nominal conditional exact 95% CI:
[0.008761, 2.575050]; two-sided p=.482973. Fisher uses a conditional estimator,
which differs slightly from the sample OR returned by exponentiating the GLM
coefficient. These calculations use an independent-PA reference distribution.
They are not game-clustered inference and do not adjust for batter or context.
Exact calculation for a sparse table does not eliminate dependence or confounding.

Only 13 exposed PAs, across nine games and six batters, contribute to the contrast.
There is only one exposed strikeout, in the August 14 game. Removing that game
leaves 11 exposed PAs and zero exposed strikeouts: the exposure-only logistic
coefficient then has no finite maximum likelihood estimate. The reported zero
sample OR in that omitted-game table is a boundary result, not proof of protection.
The remaining omitted-game ORs do not compensate for that lack of event support.

The reference interval permits large associations in either direction. We cannot
conclude that disruption reduces strikeouts, that the association is absent, or
that outcomes are equivalent. The sample does not support a reliable richly
adjusted estimate of the first-pitch disruption association. No many-parameter
logistic model or automated predictor selection was applied.

## Timing matters

Any disruption during a PA occurs in 50 PAs (six strikeouts). In 37 of those PAs,
first disruption occurs after pitch one; 15 first disruptions are recorded on the
terminal pitch. A terminal-pitch flag does not mean the disruption occurred after
the outcome. Any-disruption PAs average 5.16 pitches versus 3.7648 otherwise.
More pitches provide more exposure opportunities, so retrospective any-disruption
and first-pitch exposure address different questions. Total PA length is not a
baseline confounder to add automatically. The any-disruption comparison remains
descriptive, not a replacement selected for a larger exposure count.

Observed zero-disruption dates remain valid under the user's provenance declaration.
No dates were discarded merely because their exposure counts were zero.

## Conclusion for the portfolio

The observed first-pitch-disrupted group has a lower strikeout proportion, but
exposure and event support are too limited to establish a stable adjusted
association. Workstream 2 demonstrates exposure definition, timing audits,
logistic interpretation and transparent reporting of estimation limits. A stronger
study would collect more consistently observed exposed PAs across games and
batters, recording disruption type and timing prospectively. No target sample
size or causal identification claim is made here.

## Reproducibility

Diagnostic run: `outputs/project2/diagnostics/20261002_153144_23628`.
Association run: `outputs/project2/association/20261002_155625_23628`.
All 14 association files are retained. Ten input hashes match. Cohort IDs,
descriptive rates, GLM coefficients/probabilities and all 27 omitted-game counts
were independently checked. Fisher results were independently recomputed with
SciPy: point/interval values agree within 0.00003 due to numerical inversion
tolerances; the p-value agrees. The RDS was preserved but not deserialized here.
No validation or test outcomes were analyzed by these scripts.

This completes the initial first-pitch-disruption/strikeout scope. Other outcomes
and more complex adjusted models were not established by this analysis.

Method references:
- https://www.stat.ethz.ch/R-manual/R-devel/library/stats/html/fisher.test.html
- https://stat.ethz.ch/R-manual/R-patched/library/stats/html/glm.html
