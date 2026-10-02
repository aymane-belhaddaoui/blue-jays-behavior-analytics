# Workstream 3 — First temporal benchmark review

## @Aymane's projects

Reviewed run: `outputs/project3/baselines/20261002_161931_23628`.
GitHub remains private until all four workstreams are finished. Workstreams 1
and 2 have documented initial research milestones; Workstream 3 is in development,
and Workstream 4 remains pending. No Validation/Test performance has been assessed.

## Verified results

The run contains 13 files. All ten input hashes match. The 2,304 saved probability
predictions (four models × 576 assessment PAs) were independently reproduced from
the canonical training CSVs using logistic IRLS and fold prevalence calculations.
Maximum absolute probability difference was below 2e-12. Fold membership,
chronological separation and every reported fold/pooled metric were checked.
The RDS was preserved but not deserialized in the review environment.

| Model | Log loss | Brier score | Pooled ROC-AUC |
|---|---:|---:|---:|
| Prevalence | 0.470701 | 0.147167 | 0.439828 |
| Context | 0.478147 | 0.149519 | 0.467928 |
| Behavior | 0.469746 | 0.146584 | 0.531035 |
| Context + behavior | 0.477169 | 0.149116 | 0.485355 |

Behavior improves pooled log loss by 0.000955 (about 0.20% relative to baseline)
and Brier by 0.000584. This is a very small development improvement, not evidence
of established practical utility. Behavior log loss is worse than prevalence in
fold 1, slightly better in folds 2 and 3. Behavior's fold AUCs are approximately
0.520, 0.561 and 0.559. These weak ranking results need confirmation on later data.

The constant benchmark has AUC=0.5 within every fold. Its pooled AUC=0.440 is
possible because each fold has a different fitted prevalence; the pooled ordering
therefore incorporates between-period changes. It is not an implementation error
or evidence of within-fold predictive discrimination. Inspect fold AUCs alongside
pooled AUC; probability scores remain the primary comparison.

At the diagnostic 0.5 threshold, every model predicts no strikeout for every PA.
All achieve 473/576=82.12% accuracy, zero recall, and undefined precision (NA,
because there are no positive predictions). Do not convert NA precision to a
successful zero-false-positive narrative. Lowering the threshold could trade
precision for recall, but cannot improve the ROC ranking or probability scores.
There is no justified operational threshold yet because decision costs are unspecified.

The Workstream 1 associations do not guarantee outcome predictability. Those
models asked how behavior changes with RISP; these models ask whether recorded
features forecast eventual strikeout. Neither the small score improvement nor
the earlier association establishes causality.

## Next bounded candidate round

Script 11 compares four fixed candidates on exactly the same temporal windows:

- M4: ridge logistic regression, player/opponent/context features.
- M5: the same feature family plus behavior.
- M6: probability random forest, player/opponent/context features.
- M7: the same feature family plus behavior.

Context is RISP, home/road and inning. Identity adds batter and opponent categories.
Behavior remains log duration and tic count. This is a stronger comparison than
claiming behavioral value over a context model that ignores player differences.
Categorical levels and zero-variance filtering are learned in each fitting window.
No target encoding, held-out levels, class balancing or resampling is used.
Unseen categories receive all-zero indicators for that field and are logged;
this is a fallback representation, not an estimate specific to a new category.

There are 0/8/4 assessment rows with unseen batters and 187/38/118 rows with unseen
opponents in folds 1/2/3. Thus opponent identity is especially limited as a
forecasting feature here. This is expected and must remain visible in the audit.
A successful comparison does not demonstrate performance on arbitrary unseen players.

Ridge alpha=0 and assessed lambda=.01 are fixed for this round. The .1/.03/.01
lambda path supplies warm starts; .1 and .03 are not separately selected by scores.
Standardization is fitted within glmnet using fit-window data only. Ridge shrinks
coefficient magnitudes; it does not create information about sparse categories.

Forests use 500 trees, min.node.size=20, mtry=floor(sqrt(number of encoded features)),
gini splits, a fixed seed per fold and one thread. min.node.size specifies the
node-size splitting threshold, not a guaranteed minimum leaf size. The probability
forest averages tree probability estimates. Settings are fixed rather than tuned
across many trials. The mtry rule changes its numeric value when feature counts
change, so the with/without behavior comparison includes that prescribed change.

Review fold results and within-family behavior differences, then freeze a shortlist
for Validation. Do not keep adding models until a favorable result appears. This
round was designed after reviewing script10 and is exploratory; repeated development
on the same folds does not give unbiased final performance estimates. Test remains
reserved for one final assessment after model/threshold choices are frozen.

## Run instructions

Merge this update's `scripts`, `docs` and `outputs` into the working repository.
Install packages once in the R console:

```r
install.packages(c("glmnet", "ranger"))
```

Then run from the repository root:

```r
source("scripts/11_project3_candidates.R")
```

The script uses the submitted script10 RDS and verifies its recorded input hashes.
It writes all eight models' fold and pooled metrics, per-PA probabilities,
within-family behavior comparisons, encoding audits, fitted objects, hashes and
session information to `outputs/project3/candidates/<timestamp>/`.
Send that folder as a ZIP, including warnings.txt if present. Script 11 was
inspected but its R package fits have not been executed here.

Suggested commit after execution:
`Compare player-aware ridge and forest prediction candidates`

Push origin while retaining private visibility. This update records results and
code for that commit; no remote repository changes were performed by the assistant.

Sources:
- https://imbs-hl.github.io/ranger/reference/ranger.html
- https://imbs-hl.github.io/ranger/reference/predict.ranger.html
- https://stat.ethz.ch/CRAN/web/packages/glmnet/vignettes/glmnet.pdf

## @Ilias' projects

No updates in this checkpoint.
