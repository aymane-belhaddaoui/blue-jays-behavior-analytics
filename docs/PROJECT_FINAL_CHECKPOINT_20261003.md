# Four-workstream analytical close — October 3, 2026

## Current status

All four initial analytical workstreams are complete within the questions and cohorts documented in their reports. The project now moves to final presentation and publication preparation. No further model-selection round is required to complete this scope.

| Area | Status |
|---|---|
| Relational data and project extracts | Current analytical inputs validated and retained |
| Workstream 1 | Reviewed context/behavior analyses and sensitivity results complete |
| Workstream 2 | Reviewed initial first-pitch disruption/strikeout scope complete; sparse support explicitly limits inference |
| Workstream 3 | Final test assessment complete; selected model did not beat prevalence on test log loss or Brier; selection closed |
| Workstream 4 | Game export, supplied Power BI QA, and final descriptive associations reviewed |
| Dashboard presentation | Overview improvements accepted; small game-detail corrections remain |
| Portfolio synthesis | Prepared in this package |
| Root README | Proposed replacement prepared for the user's review and placement |
| GitHub/LinkedIn publication | Not performed; repository remains private by the user's standing instruction |

## Evidence inventory

| Stage | Repository-relative archived run |
|---|---|
| W1 models | `outputs/project1/models/20261002_111847_28440/` |
| W1 sensitivity | `outputs/project1/sensitivity/20261002_120419_28440/` |
| W1 tics | `outputs/project1/tics/20261002_122622_28440/` |
| W1 summary | `outputs/project1/summary/20261002_125309_28440/` |
| W2 diagnostics | `outputs/project2/diagnostics/20261002_153144_23628/` |
| W2 sparse association | `outputs/project2/association/20261002_155625_23628/` |
| W3 chronological baselines | `outputs/project3/baselines/20261002_161931_23628/` |
| W3 richer candidates | `outputs/project3/candidates/20261002_164056_23628/` |
| W3 validation | `outputs/project3/validation/20261002_202247_23628/` |
| W3 final test | `outputs/project3/final_test/20261002_205859_23628/` |
| W4 game KPIs | `outputs/project4/game_kpis/20261002_214708_23628/` |
| W4 first Power BI review | `outputs/project4/powerbi_qa/20261003_review/` |
| W4 final associations | `outputs/project4/associations/20261003_194642_19800/` |
| W4 revised screenshots | `outputs/project4/powerbi_qa/20261003_final_screenshots/` |

Earlier runs were supplied in earlier incremental packages. This closing package adds the last two entries and the reviewed Workstream 4 report, synthesis, proposed README, and final verification record. It is not a replacement for the full repository.

## Source and review boundaries

The latest run's 13 input hashes match. All tabular association results were independently reconstructed in Python. The 18 original run files and two screenshots are preserved unchanged. `PROJECT4_FINAL_VERIFICATION.json` records the checks and SHA-256 archive manifest.

The user's R executions are the native execution evidence. RDS files were preserved, not deserialized in the review environment. Earlier stage reports explain their own verification scope, including Workstream 1's CR2 covariance limitations. No remote repository or native Power BI Desktop session was inspected. The supplied Power BI QA covers overall, venue, and game-level results; it does not certify every possible slicer combination.

Retain the local SQL and R source files actually used, including any local edits, and save the PBIX alongside the DAX source. A checkpoint version of script 03 exists; it should not be represented as a byte-for-byte archive of an unavailable earlier console execution. Keep that distinction in the existing script header.

Individual analytical stages are reproducible from archived inputs and recorded package versions. A single clean end-to-end automation command has not been validated, so the public README should not promise one.

## Publication handoff

1. Merge the package into the repository root. Preserve any newer local edits when resolving duplicate files.
2. In the Game details table, set `game_order` to **Don't summarize**, rename its visible label to **Game order**, and confirm the meaningless total 780 disappears. This is an ordering field, not an additive measure.
3. Add `[Mean Game Routine Seconds]` to that table alongside tic count. Increase the header/body text to a readable size, such as 11–12 pt, and use a short date format. Vertical scrolling is acceptable; game IDs must remain visible.
4. Save the updated PBIX in `deliverables/workstream4/powerbi/`. Replace the presentation copies `deliverables/workstream4/overview.png` and `game_details.png` with the final exported views after these edits. Preserve the submitted review screenshots in their immutable output folders.
5. Review `docs/PORTFOLIO_README.md`, then place its approved contents in the repository-root `README.md`. Its relative links are designed for that root location. It references earlier reports already in the repository. After the presentation edits are saved, update its status sentence to reflect the final state.
6. Commit and push the completed materials to the private repository. Suggested commit: `Complete four-workstream analysis and add portfolio synthesis`.

Public visibility and a LinkedIn announcement are the next release decisions. Neither has been changed or posted here. The analytical close is complete; publication should describe the actual limitations and benchmark result rather than claim a successful strikeout predictor or causal momentum discovery.
