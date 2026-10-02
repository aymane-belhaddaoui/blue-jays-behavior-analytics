# View the total count of NA values for each column in a dataset
colSums(is.na(p1_routine))

# Alternatively, get a full summary which includes NA counts for numeric variables
summary(train)

# Basic frequency count of strikeouts in the training set
table(train$target_strikeout)

# Proportional frequency table (percentages)
prop.table(table(p2$disrupted_first_pitch))

# Cross-tabulation of two variables
table(train$target_strikeout, train$pitch_number_pa)

# Calculate summary statistics for routine time grouped by batter
aggregate(routine_time_secs ~ batter_id, data = p1_routine, FUN = summary)

# Visually compare the distributions using a boxplot
boxplot(routine_time_secs ~ batter_id, data = p1_routine,
        main = "Routine Time Distribution by Batter",
        xlab = "Batter ID", ylab = "Seconds")

# Compare mean routine time based on RISP context
aggregate(routine_time_secs ~ risp, data = p1_routine, FUN = mean)

# Cross-tabulate RISP with strikeout outcomes
## Merge the two dataframes together based on their shared columns
combined_data <- merge(train, p1_routine)

## Now run the table on the newly combined dataset
table(combined_data$risp, combined_data$target_strikeout)

# Visually compare routine times with and without RISP
boxplot(routine_time_secs ~ risp, data = p1_routine,
        main = "Routine Time by RISP",
        xlab = "RISP (0 = No, 1 = Yes)", ylab = "Seconds")

