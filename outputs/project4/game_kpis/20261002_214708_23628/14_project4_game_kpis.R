# Workstream 4: descriptive game KPIs and Power BI import tables.
# Run from the repository root: source("scripts/14_project4_game_kpis.R")
# Base R only. Core CSVs stay unchanged; all 5,634 pitches are retained in export.
# All 39 games are used for this separate descriptive analysis. Project 3 is closed.
run_project4_game_kpis <- function() {
  final_dir <- "outputs/project3/final_test/20261002_205859_23628"
  previous <- read.csv(file.path(final_dir, "input_hashes.csv"), stringsAsFactors=FALSE)
  data_hashes <- previous[grepl("^data/", previous$file), ]
  current <- tools::md5sum(data_hashes$file)
  stopifnot(nrow(data_hashes)==8, !anyNA(current),
            all(unname(current)==data_hashes$md5))
  source("scripts/01_import_R.R", local=TRUE)
  g <- tables$games[order(tables$games$game_order), ]
  pa <- tables$plate_appearances
  p <- tables$pitches
  b <- tables$batters
  flat <- tables$project4_games
  stopifnot(nrow(g)==39, nrow(pa)==1461, nrow(p)==5634, nrow(b)==17,
            !anyDuplicated(g$game_id), !anyDuplicated(b$batter_id),
            !anyDuplicated(pa$pa_id), !anyDuplicated(p$pitch_id),
            all(g$game_order==seq_len(nrow(g))),
            all(diff(as.Date(g$game_date))>=0),
            all(g$win %in% 0:1), all(g$home %in% 0:1),
            all(g$run_differential==g$runs_for-g$runs_against),
            all(g$win==as.integer(g$run_differential>0)),
            all(g$run_differential!=0),
            all(g$result==ifelse(g$win==1, "W", "L")),
            all(pa$game_id %in% g$game_id), all(pa$batter_id %in% b$batter_id),
            all(p$pa_id %in% pa$pa_id), all(pa$pa_sequence_valid %in% 0:1),
            !anyDuplicated(flat$game_id), setequal(flat$game_id, g$game_id))
  flat <- flat[match(g$game_id, flat$game_id), names(g)]
  rownames(g) <- rownames(flat) <- NULL
  stopifnot(isTRUE(all.equal(g, flat, check.attributes=FALSE)))

  # A match joins exactly one PA to each pitch while preserving original pitch order.
  j <- match(p$pa_id, pa$pa_id)
  stopifnot(!anyNA(j))
  fact <- cbind(p, pa[j, c("game_id", "batter_id", "inning", "pa_sequence_valid")])
  rownames(fact) <- NULL
  stopifnot(identical(fact$pitch_id, p$pitch_id), nrow(fact)==5634,
            all(fact$risp %in% 0:1), all(fact$pitcher_disruption %in% 0:1),
            all(is.finite(fact$routine_time_secs[!is.na(fact$routine_time_secs)])),
            all(fact$routine_time_secs[!is.na(fact$routine_time_secs)]>0),
            all(fact$total_tics[!is.na(fact$total_tics)]>=0),
            all(fact$total_tics[!is.na(fact$total_tics)]==floor(fact$total_tics[!is.na(fact$total_tics)])))
  fact$valid_pa_eligible <- as.integer(fact$pa_sequence_valid==1)
  fact$routine_observed_eligible <- as.integer(
    fact$valid_pa_eligible==1 & fact$routine_source %in% "Observed" &
      !is.na(fact$routine_time_secs))
  fact$routine_primary_eligible <- as.integer(
    fact$routine_observed_eligible==1 & fact$pitcher_disruption==0)
  fact$tics_observed_eligible <- as.integer(
    fact$valid_pa_eligible==1 & fact$tics_source %in% "Observed" & !is.na(fact$total_tics))
  fact$tics_primary_eligible <- as.integer(
    fact$tics_observed_eligible==1 & fact$pitcher_disruption==0)
  stopifnot(sum(fact$valid_pa_eligible)==5627,
            sum(fact$routine_observed_eligible)==5623,
            sum(fact$routine_primary_eligible)==5553,
            sum(fact$tics_observed_eligible)==5624,
            sum(fact$tics_primary_eligible)==5554)
  mean_or_na <- function(x) if(length(x)) mean(x) else NA_real_
  sd_or_na <- function(x) if(length(x)>1) sd(x) else NA_real_
  kpis <- do.call(rbind, lapply(g$game_id, function(id) {
    z <- fact[fact$game_id==id, ]
    valid <- z[z$valid_pa_eligible==1, ]
    ro <- z$routine_time_secs[z$routine_observed_eligible==1]
    ru <- z$routine_time_secs[z$routine_primary_eligible==1]
    to <- z$total_tics[z$tics_observed_eligible==1]
    tu <- z$total_tics[z$tics_primary_eligible==1]
    data.frame(game_id=id, all_pitch_n=nrow(z), all_pa_n=length(unique(z$pa_id)),
      valid_pitch_n=nrow(valid), valid_pa_n=length(unique(valid$pa_id)),
      invalid_pa_pitch_n=sum(z$valid_pa_eligible==0),
      calculated_routine_n=sum(z$routine_source %in% "Calculated"),
      missing_routine_n=sum(is.na(z$routine_time_secs)), missing_tics_n=sum(is.na(z$total_tics)),
      routine_observed_n=length(ro), routine_observed_mean_secs=mean_or_na(ro),
      routine_undisrupted_n=length(ru), routine_undisrupted_mean_secs=mean_or_na(ru),
      routine_undisrupted_sd_secs=sd_or_na(ru),
      routine_undisrupted_cv=if(length(ru)>1) sd(ru)/mean(ru) else NA_real_,
      tics_observed_n=length(to), tics_observed_mean=mean_or_na(to),
      tics_undisrupted_n=length(tu), tics_undisrupted_mean=mean_or_na(tu),
      valid_disruption_count=sum(valid$pitcher_disruption==1),
      valid_disruption_rate=mean_or_na(valid$pitcher_disruption),
      valid_risp_rate=mean_or_na(valid$risp))
  }))
  stopifnot(all(kpis$game_id==g$game_id), all(kpis$all_pitch_n==g$pitch_count),
            all(kpis$all_pa_n==g$pa_count), all(kpis$routine_undisrupted_n>1),
            all(kpis$tics_undisrupted_n>0), sum(kpis$all_pitch_n)==5634,
            sum(kpis$all_pa_n)==1461, sum(kpis$routine_undisrupted_n)==5553)

  # DimGame includes results and one row of KPIs per game. It is not pitch-grained.
  game_cols <- c("game_id", "game_order", "game_date", "game_on_date", "home",
                 "opponent", "result", "win", "runs_for", "runs_against",
                 "run_differential", "split", "logged_offensive_innings", "disruption_coverage")
  dim_game <- cbind(g[game_cols], kpis[setdiff(names(kpis), "game_id")])
  dim_game$venue <- ifelse(dim_game$home==1, "Home", "Road")
  prior5 <- function(x) vapply(seq_along(x), function(i)
    if(i>5) mean(x[(i-5):(i-1)]) else NA_real_, numeric(1))
  trailing5 <- function(x) vapply(seq_along(x), function(i)
    if(i>=5) mean(x[(i-4):i]) else NA_real_, numeric(1))
  dim_game$prior5_win_rate <- prior5(dim_game$win)
  dim_game$prior5_routine_undisrupted_mean_secs <- prior5(dim_game$routine_undisrupted_mean_secs)
  dim_game$trailing5_win_rate <- trailing5(dim_game$win)
  dim_game$trailing5_routine_undisrupted_mean_secs <- trailing5(dim_game$routine_undisrupted_mean_secs)
  streak <- integer(nrow(g))
  for(i in 2:nrow(g)) streak[i] <- if(g$win[i-1]==1) streak[i-1]+1L else 0L
  dim_game$window_win_streak_before <- streak
  stopifnot(isTRUE(all.equal(dim_game$prior5_win_rate, g$prior_5_win_rate)),
            all(streak==g$window_win_streak_before),
            sum(is.na(dim_game$prior5_win_rate))==5,
            sum(is.na(dim_game$trailing5_win_rate))==4)

  summarize_groups <- function(variable) do.call(rbind,
    lapply(split(dim_game, dim_game[[variable]], drop=TRUE), function(z)
      data.frame(grouping=variable, level=as.character(z[[variable]][1]), games=nrow(z),
        wins=sum(z$win), win_rate=mean(z$win), mean_runs_for=mean(z$runs_for),
        mean_runs_against=mean(z$runs_against), mean_run_differential=mean(z$run_differential),
        mean_game_routine_secs=mean(z$routine_undisrupted_mean_secs),
        mean_game_tics=mean(z$tics_undisrupted_mean),
        mean_game_disruption_rate=mean(z$valid_disruption_rate))))
  summaries <- do.call(rbind, lapply(c("result", "venue", "opponent"), summarize_groups))
  flow <- data.frame(stage=c("All logged pitches", "Valid PA sequence", "Valid PA, observed routine",
    "Valid PA, observed routine, no disruption", "Valid PA, observed tics",
    "Valid PA, observed tics, no disruption"),
    pitches=c(nrow(fact), sum(fact$valid_pa_eligible), sum(fact$routine_observed_eligible),
      sum(fact$routine_primary_eligible), sum(fact$tics_observed_eligible), sum(fact$tics_primary_eligible)))
  overview <- data.frame(games=nrow(g), wins=sum(g$win), losses=sum(g$win==0),
    home_games=sum(g$home), road_games=sum(g$home==0), opponents=length(unique(g$opponent)),
    pitches=nrow(fact), plate_appearances=nrow(pa), batters=nrow(b),
    primary_routine_pitches=sum(fact$routine_primary_eligible),
    primary_tic_pitches=sum(fact$tics_primary_eligible))
  stopifnot(overview$wins==20, overview$losses==19, overview$home_games==18,
            overview$opponents==10)
  out <- file.path("outputs", "project4", "game_kpis",
    paste0(format(Sys.time(), "%Y%m%d_%H%M%S"), "_", Sys.getpid()))
  if(dir.exists(out)) stop("Output directory already exists.")
  dir.create(file.path(out, "powerbi"), recursive=TRUE)
  sink(file.path(out, "console.txt"), split=TRUE); on.exit(sink(), add=TRUE)
  withCallingHandlers({
    write_table <- function(x, filename)
      write.csv(x, file.path(out, filename), row.names=FALSE, na="", fileEncoding="UTF-8")
    write_table(dim_game, "powerbi/dim_game.csv")
    write_table(b, "powerbi/dim_batter.csv")
    write_table(fact, "powerbi/fact_pitch.csv")
    write_table(dim_game, "game_kpis.csv")
    write_table(summaries, "descriptive_group_summaries.csv")
    write_table(flow, "cohort_flow.csv")
    write_table(overview, "dataset_overview.csv")
    write_table(g, "source_game_aggregates_reference.csv")
    write_table(as.data.frame(table(fact$routine_source, useNA="ifany")), "routine_provenance_counts.csv")
    write_table(as.data.frame(table(fact$tics_source, useNA="ifany")), "tics_provenance_counts.csv")
    write_table(fact[fact$routine_primary_eligible==0 | fact$tics_primary_eligible==0,
      c("pitch_id", "pa_id", "game_id", "pa_sequence_valid", "routine_source", "tics_source",
        "pitcher_disruption", "routine_time_secs", "total_tics",
        "routine_primary_eligible", "tics_primary_eligible")], "primary_exclusion_audit.csv")
    local({
      png(file.path(out, "game_timeline.png"), width=2000, height=1300, res=180)
      on.exit(dev.off())
      par(mfrow=c(2,1), mar=c(4,5,3,2), oma=c(3,0,2,0))
      col <- ifelse(dim_game$win==1, "#167759", "#B24C41")
      plot(dim_game$game_order, dim_game$routine_undisrupted_mean_secs, type="b",
        col="#A3ABB8", pch=NA, xlab="Logged game order (doubleheaders separate)",
        ylab="Mean routine duration (seconds)", main="Observed routines in valid PAs, without disruption")
      points(dim_game$game_order, dim_game$routine_undisrupted_mean_secs, pch=19, col=col)
      lines(dim_game$game_order, dim_game$trailing5_routine_undisrupted_mean_secs, col="#175A8C", lwd=2)
      legend("topright", c("Win", "Loss", "Trailing 5 games, includes current"),
        col=c("#167759", "#B24C41", "#175A8C"), pch=c(19,19,NA), lty=c(NA,NA,1), bty="n", cex=.8)
      plot(dim_game$game_order, dim_game$prior5_win_rate, type="b", ylim=c(0,1),
        col="#175A8C", pch=19, xlab="Logged game order", ylab="Prior-five-game win rate",
        main="Pregame history: five preceding logged games, current game excluded")
      mtext("Workstream 4 | Descriptive game-level overview", outer=TRUE, side=3, font=2)
      mtext("39 logged games; observational. Rolling routine means weight games equally. No win prediction or causal claims.",
        outer=TRUE, side=1, line=1, cex=.8)
    })
    writeLines(c(
      "Workstream 4 uses all 39 games as a separate descriptive analysis. Project 3 model selection is closed.",
      "FactPitch: one row per pitch; all 5,634 source rows retained. DimGame: one row per game. DimBatter: one row per batter.",
      "Primary duration: observed routine, valid PA sequence, no pitcher disruption. No duration truncation or winsorization.",
      "Primary tics: observed tics, valid PA sequence, no pitcher disruption. A calculated routine can have observed eligible tics.",
      "Observed duration/tic KPIs without 'undisrupted' include disruptions, but still require valid PA and observed measurement.",
      "Valid disruption and RISP rates use all valid-PA pitches as denominator, regardless of routine/tic availability.",
      "Calculated and missing measurements are preserved and flagged; missing values are exported as blanks, never replaced by zero.",
      "source_game_aggregates_reference.csv preserves original broader source aggregates; it is not a Power BI import table.",
      "Per-game primary means weight eligible pitches equally within that game; group and rolling summaries weight games equally.",
      "prior5 means use five preceding logged games and exclude current game. First five rows are blank.",
      "trailing5 means use current and four preceding logged games. First four rows are blank. These are retrospective.",
      "Windows follow game_order, not calendar-day spacing, and remain fixed to the full logged timeline under BI slicers.",
      "window_win_streak_before resets at the start of this data window; season history before the first game is unknown.",
      "game_timestamp is omitted from the BI export: its artificial doubleheader offset is not an observed start time.",
      "logged_offensive_innings is the logged offensive coverage, not total game duration or total innings played.",
      "Same-game behavior is measured during the game and is not a pregame predictor. Momentum associations do not establish causality.",
      "The independent observational units for game-outcome comparisons are 39 games, not 5,634 pitches; serial/team dependence remains possible.",
      "No hypothesis-test p-values, model fitting, threshold tuning or post-test model changes are performed here.",
      "Use only the three files in powerbi/ as import tables; join each dimension 1:* to FactPitch with single-direction filtering.",
      "DimBatter filters FactPitch only. It does not alter DimGame win counts or precomputed game KPIs/rolling history.",
      "GitHub remains private until all four workstreams are finished."), file.path(out, "DEFINITIONS.txt"))
    inputs <- c("scripts/14_project4_game_kpis.R", "scripts/01_import_R.R", data_hashes$file)
    h <- tools::md5sum(inputs); stopifnot(!anyNA(h))
    write_table(data.frame(file=names(h), md5=unname(h)), "input_hashes.csv")
    stopifnot(file.copy("scripts/14_project4_game_kpis.R", file.path(out, "14_project4_game_kpis.R")))
    saveRDS(list(dim_game=dim_game, dim_batter=b, fact_pitch=fact,
      group_summaries=summaries, cohort_flow=flow, overview=overview), file.path(out, "project4_game_kpis.rds"))
    writeLines(capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
    print(overview); print(flow); print(summaries)
    writeLines("Game KPI export completed; independent output review and Power BI build remain pending.", file.path(out, "RUN_COMPLETE.txt"))
    cat("\nWorkstream 4 outputs saved in:", out, "\n")
  }, warning=function(w) cat(conditionMessage(w), "\n", file=file.path(out, "warnings.txt"), append=TRUE))
  invisible(out)
}
project4_game_kpis_output <- run_project4_game_kpis()
