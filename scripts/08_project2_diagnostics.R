# Workstream 2: training PA cohort, exposure timing and event support.
# No regression or holdout outcome inspection in this script.
# From project root: source("scripts/08_project2_diagnostics.R")
run_project2_diagnostics <- function() {
  source("scripts/01_import_R.R",local=TRUE)
  d <- subset(tables$project2_pas,split=="Train")
  pa <- tables$plate_appearances
  stopifnot(!anyDuplicated(d$pa_id),!anyDuplicated(pa$pa_id),nrow(d)==1028,
            all(complete.cases(d[c("pa_id","game_id","batter_id","risp_start",
                                  "disrupted_first_pitch","disrupted_any","strikeout")])) )
  idx <- match(d$pa_id,pa$pa_id)
  stopifnot(!anyNA(idx),all(pa$outcome_model_eligible[idx]==1),
            all(pa$pa_sequence_valid[idx]==1),all(pa$outcome_inferred[idx]==0),
            all(d$strikeout==pa$strikeout[idx]),
            all(d$strikeout %in% c(0,1)),all(d$disrupted_first_pitch %in% c(0,1)),
            all(d$disrupted_any %in% c(0,1)),
            all(d$disrupted_first_pitch<=d$disrupted_any))
  p <- tables$pitches[tables$pitches$pa_id %in% d$pa_id,]
  stopifnot(!anyDuplicated(p$pitch_id),all(p$pitcher_disruption %in% c(0,1)),
            all(p$disruption_source=="Observed"))
  grouped <- split(p,p$pa_id)
  timing <- do.call(rbind,lapply(d$pa_id,function(id) {
    z <- grouped[[id]];z <- z[order(z$pitch_number_pa),]
    stopifnot(sum(z$pitch_number_pa==1)==1,!anyDuplicated(z$pitch_number_pa))
    k <- which(z$pitcher_disruption==1)
    first <- if(length(k)) k[1] else NA_integer_
    data.frame(pa_id=id,pitch_count=nrow(z),disrupted_pitches=length(k),
               disrupted_first_pitch=z$pitcher_disruption[1],disrupted_any=as.integer(length(k)>0),
               first_disruption_pitch=if(length(k)) z$pitch_number_pa[first] else NA_integer_,
               pre_balls_at_first_disruption=if(length(k)) z$pre_balls[first] else NA_real_,
               pre_strikes_at_first_disruption=if(length(k)) z$pre_strikes[first] else NA_real_,
               first_disruption_on_terminal_pitch=if(length(k)) z$is_terminal[first] else NA_integer_)
  }))
  stopifnot(identical(as.character(timing$pa_id),as.character(d$pa_id)),
            all(timing$pitch_count==d$pitch_count),
            all(timing$disrupted_pitches==d$disrupted_pitches),
            all(timing$disrupted_first_pitch==d$disrupted_first_pitch),
            all(timing$disrupted_any==d$disrupted_any))
  timing$game_id <- d$game_id; timing$batter_id <- d$batter_id
  timing$strikeout <- d$strikeout
  out <- file.path("outputs","project2","diagnostics",
                   paste0(format(Sys.time(),"%Y%m%d_%H%M%S"),"_",Sys.getpid()))
  if(dir.exists(out)) stop("Run folder already exists.")
  dir.create(out,recursive=TRUE)
  sink(file.path(out,"console.txt"),split=TRUE);on.exit(sink(),add=TRUE)
  withCallingHandlers({
    cat("TRAINING PA COHORT\n")
    print(c(pas=nrow(d),games=length(unique(d$game_id)),batters=length(unique(d$batter_id)),
            strikeouts=sum(d$strikeout)))
    counts <- do.call(rbind,lapply(c("disrupted_first_pitch","disrupted_any"),function(ex) {
      do.call(rbind,lapply(0:1,function(v) {
        z <- d[d[[ex]]==v,]
        data.frame(exposure=ex,value=v,pas=nrow(z),strikeouts=sum(z$strikeout),
                   non_strikeouts=sum(z$strikeout==0),strikeout_fraction=mean(z$strikeout),
                   games=length(unique(z$game_id)),batters=length(unique(z$batter_id)))
      }))
    }))
    print(counts);write.csv(counts,file.path(out,"exposure_outcome_counts.csv"),row.names=FALSE)
    for(key in c("batter_id","game_id")) {
      support <- do.call(rbind,lapply(split(d,d[[key]]),function(z) {
        data.frame(id=as.character(z[[key]][1]),pas=nrow(z),strikeouts=sum(z$strikeout),
                   first_pitch_exposed=sum(z$disrupted_first_pitch),
                   exposed_strikeouts=sum(z$strikeout[z$disrupted_first_pitch==1]),
                   any_disrupted=sum(z$disrupted_any))
      }))
      cat("\nSUPPORT BY",key,"\n");print(support)
      write.csv(support,file.path(out,paste0(key,"_support.csv")),row.names=FALSE)
    }
    contexts <- as.data.frame(with(d,table(disrupted_first_pitch=factor(disrupted_first_pitch,levels=0:1),
                                         risp_start=factor(risp_start,levels=0:1),strikeout=factor(strikeout,levels=0:1))))
    print(contexts);write.csv(contexts,file.path(out,"first_pitch_by_risp_and_outcome.csv"),row.names=FALSE)
    length_summary <- do.call(rbind,lapply(0:1,function(v) {
      x <- d$pitch_count[d$disrupted_any==v]
      data.frame(disrupted_any=v,n=length(x),mean_pitches=mean(x),median_pitches=median(x),max_pitches=max(x))
    }))
    cat("\nPA LENGTH BY ANY DISRUPTION (descriptive)\n");print(length_summary)
    write.csv(length_summary,file.path(out,"pa_length_by_any_disruption.csv"),row.names=FALSE)
    cat("\nFIRST DISRUPTION POSITION\n");print(table(timing$first_disruption_pitch,useNA="ifany"))
    cat("\nFIRST DISRUPTION ON TERMINAL PITCH\n");print(table(timing$first_disruption_on_terminal_pitch,useNA="ifany"))
    write.csv(timing,file.path(out,"pa_disruption_timing.csv"),row.names=FALSE)
    write.csv(d[c("pa_id","game_id","batter_id")],file.path(out,"cohort_ids.csv"),row.names=FALSE)
    saveRDS(list(train_pas=d,timing=timing,exposure_counts=counts),file.path(out,"project2_diagnostics.rds"))
    files <- c("scripts/08_project2_diagnostics.R","scripts/01_import_R.R",
               list.files("data",pattern="[.]csv$",full.names=TRUE))
    hashes <- tools::md5sum(files);stopifnot(!anyNA(hashes))
    write.csv(data.frame(file=names(hashes),md5=unname(hashes)),file.path(out,"input_hashes.csv"),row.names=FALSE)
    stopifnot(file.copy("scripts/08_project2_diagnostics.R",file.path(out,"08_project2_diagnostics.R")))
    writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
    writeLines(c("Completed training PA diagnostics; no outcome model fitted.",
                 "Primary candidate exposure: first-pitch disruption. Any disruption is retrospective and opportunity-dependent.",
                 "Total PA pitch count is not a baseline adjustment variable. Sparse exposure/event cells require model review."),
               file.path(out,"RUN_COMPLETE.txt"))
    cat("\nProject 2 diagnostics saved in:",out,"\n")
  },warning=function(w)cat(conditionMessage(w),"\n",file=file.path(out,"warnings.txt"),append=TRUE))
  invisible(out)
}
project2_diagnostics_output <- run_project2_diagnostics()
