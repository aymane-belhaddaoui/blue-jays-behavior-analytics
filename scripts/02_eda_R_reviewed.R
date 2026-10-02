# Reviewed development-only version. Original user script is preserved as 02_eda_R.R.
# This is reference code; rerunning EDA is not required before script 05.
source("scripts/01_import_R.R")
p1_development <- subset(p1_routine,split=="Train")
p2_development <- subset(p2,split=="Train")
print(colSums(is.na(p1_development)))
print(summary(train))
print(table(train$target_strikeout))
print(prop.table(table(p2_development$disrupted_first_pitch)))
print(table(train$target_strikeout,train$pitch_number_pa))
print(aggregate(routine_time_secs ~ batter_id,data=p1_development,FUN=summary))
print(aggregate(routine_time_secs ~ risp,data=p1_development,FUN=mean))

# Explicit many-to-one join: train has one row per first-pitch ID; the lookup has
# exactly one row per pitch ID. match preserves left-table row order and grain.
lookup <- p1_development[c("pitch_id","risp")]
stopifnot(!anyDuplicated(train$pitch_id),!anyDuplicated(lookup$pitch_id))
idx <- match(train$pitch_id,lookup$pitch_id)
stopifnot(!anyNA(idx))
combined_data <- train
combined_data$risp <- lookup$risp[idx]
stopifnot(nrow(combined_data)==nrow(train),!anyDuplicated(combined_data$pitch_id))
print(table(combined_data$risp,combined_data$target_strikeout))

out <- file.path("outputs","eda",paste0(format(Sys.time(),"%Y%m%d_%H%M%S"),"_",Sys.getpid()))
if(dir.exists(out)) stop("Run directory already exists.")
dir.create(out,recursive=TRUE)
local({
  pdf(file.path(out,"training_routine_boxplots.pdf"),width=10,height=6)
  on.exit(dev.off())
  boxplot(routine_time_secs ~ batter_id,data=p1_development,
          main="Training-period routine duration by batter",xlab="Batter ID",ylab="Seconds")
  boxplot(routine_time_secs ~ risp,data=p1_development,
          main="Training-period routine duration by RISP",xlab="RISP",ylab="Seconds")
})
writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
