# Workstream 4 — Start Power BI

The submitted R export passed review. This package is an incremental update for the existing repository.

1. Merge this folder's contents into the repository root.
2. Follow `docs/POWERBI_BUILD_GUIDE.md` to import the three CSVs from the archived run into Power BI Desktop.
3. Name the tables DimGame, DimBatter, and FactPitch; create the two one-to-many relationships described in the guide.
4. Run `scripts/15_project4_powerbi_measures.dax` in DAX query view, compare its results, and save the measures into the model.
5. Run `scripts/16_project4_powerbi_checks.dax`, build the initial overview page, and save the PBIX in the repository.
6. Return QA TSV files and screenshots as listed in the guide. The next step is Power BI; no new R script is required first.

The package includes the unchanged 19-file R run, a verification record, descriptive review, seven numerical reference CSVs, two DAX source files, and the build guide. No PBIX has been created or executed here. Keep the GitHub repository private.

Suggested commit message for this reviewed checkpoint: `Verify game KPI export and add Power BI measures and build guide`.
