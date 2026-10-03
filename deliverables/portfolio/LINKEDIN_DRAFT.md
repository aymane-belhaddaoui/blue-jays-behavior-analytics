# LinkedIn launch draft

Draft only. Replace `[PUBLIC_REPOSITORY_URL]` after the repository is public. Attach the final overview screenshot. The text below is the proposed post.

---

Can the routines before a pitch tell us something about what happens next?

I explored that question in an independent baseball analytics project built around a log of 39 Toronto Blue Jays games: 17 batters, 1,461 plate appearances and 5,634 pitches.

As a General Engineering student at École Centrale Casablanca, I wanted to connect process measurement, statistical reasoning and decision support—the direction I want to pursue in Management Engineering.

The project brought together four workstreams:

• SQL Server data engineering and R analysis of routine duration and recorded behavior counts across game contexts.
• Disruption–strikeout analysis, where sparse exposure data limited what could be estimated reliably.
• Chronological strikeout prediction, with training folds, validation selection and a final later-period test.
• A Power BI dashboard linking game-level behavioral summaries with results and recent game history.

The most useful finding came from the benchmark comparison. Behavior varied with context, but the selected behavioral model did not improve test log loss or Brier score over a simple prevalence baseline.

That distinction matters: an association can be informative without producing a useful prediction or establishing a causal effect.

The repository includes the data dictionary, eligibility rules, SQL and R scripts, archived outputs, research summaries and Power BI report. It also documents the limits of a short observational window and the decisions made along the way.

Project and findings: [PUBLIC_REPOSITORY_URL]

I would welcome feedback on the evaluation design and the transition from statistical findings to decision support.

#DataAnalytics #ManagementEngineering #SportsAnalytics #RStats #PowerBI
