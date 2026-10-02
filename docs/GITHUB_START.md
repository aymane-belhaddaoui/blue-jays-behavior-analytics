# Start GitHub now: one repository, four workstreams

Recommended repository name: `blue-jays-behavior-analytics`.
Use Workstream 1 as the first research milestone. Build the remaining three in
the same repository because they share the relational data and preparation.
Start private for initial organization, then make it public as a clearly marked
work in progress once the README and file selection are reviewed. Completion of
all four workstreams is not a prerequisite for a public repository. Reserve the
full portfolio launch on LinkedIn for the integrated project story.

## Set up using GitHub Desktop on Windows

1. Install GitHub Desktop from https://desktop.github.com/ and sign in.
2. Choose File > New repository. Name it `blue-jays-behavior-analytics` and choose
   a permanent local parent folder. Allow Desktop to create this repository folder.
   No need to choose a license during this initial private setup.
3. From the updated project package, copy these folders into the repository root:
   `data`, `scripts`, `metadata`, `outputs`, `deliverables`, and `docs`.
   Copy the package's `.gitignore` as well. This includes archived RDS model
   objects needed by script 05, saved CSV inference results needed by script 07,
   and the completed R summary run. Do not copy the enclosing package directory
   inside the repository; `data` and `scripts` must be directly at its root.
4. Copy `docs/GITHUB_README.md` to the repository root and rename that copy to
   `README.md`. This is the concise portfolio README, not the historical package
   README. Do not upload the entire ZIP as the repository's only content.
5. Copy your original local script 03 and any locally edited SQL scripts into
   their matching `scripts` paths after comparing them with the supplied versions.
   Your original local script 03 and local SQL edits have not yet been supplied
   for archival review; the package contains previously prepared versions.
6. Open an RStudio project at this new repository root (File > New Project >
   Existing Directory), and use this location as the working project going
   forward. Avoid editing two competing copies of the same project.
7. In GitHub Desktop inspect Changes. The first meaningful checkpoint should
   include CSV data, metadata, code and research outputs. Screenshots, workbook
   duplicates, workspace caches and ZIP backups are excluded by `.gitignore`.
8. Commit with summary `Complete Workstream 1 exploratory analysis and summary`.
9. Click Publish repository. Keep `Keep this code private` selected for the first
   upload. This publishes the repository to your account without making it public.
10. Inspect the README, report image, files and reproduction steps on GitHub.
    Then change visibility to Public when you are satisfied with the presentation
    and the intended data/code sharing terms. Retain the explicit work-in-progress
    label; do not present this independent portfolio as an official PoliMi project.

This document is an instruction guide. No remote repository has been created,
uploaded or published by the assistant, and no software/data license has been
chosen on the user's behalf.

## Subsequent work

Commit a meaningful completed change, for example `Audit Workstream 2 exposure
timing and sparse outcome support`, then Push origin. A local commit records a
version on your computer; a push sends those commits to GitHub. Keep the timestamped
input hashes and session information with their analytical runs. A repository
complements the archival package; it does not replace your original observations.

Workstream 1 can later be tagged `v0.1-workstream1` as a research milestone;
there is no need to create a release immediately. Add Workstreams 2–4 incrementally
and reserve `v1.0` for the integrated report, models and dashboard. Version labels
express project maturity, not statistical certainty.

Official guides:
- https://docs.github.com/en/desktop/overview/creating-your-first-repository-using-github-desktop
- https://docs.github.com/en/desktop/adding-and-cloning-repositories/adding-an-existing-project-to-github-using-github-desktop
- https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository
