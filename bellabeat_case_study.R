# Setting up my environment
library(tidyverse)
library(ggplot2)
library(dplyr)
library(skimr)
library(lubridate)
library(stringr)

# Importing the relevant spreadsheet files
dailyActivity = read_csv("dailyActivity_merged.csv")
sleepDay = read_csv("sleepDay_merged.csv")
weightLog = read_csv("weightLogInfo_merged.csv") # contains demographics data

# Cleaning (1): formatting data type: converting "character" date types to date 
dailyActivity$ActivityDate = mdy(dailyActivity$ActivityDate)

sleepDay = sleepDay %>% 
  separate(SleepDay, into=c('Date', 'Time'), sep=" ") %>% 
  select(-Time)
weightLog = weightLog %>% 
  separate(Date, into=c('Date', 'Time'), sep=" ") %>% 
  select(-Time)
sleepDay$Date = mdy(sleepDay$Date)
weightLog$Date = mdy(weightLog$Date)

# Removing white spaces;
dailyActivity = dailyActivity %>%
  mutate_if(is.character, str_trim)
weightLog = weightLog %>%
  mutate_if(is.character, str_trim)
sleepDay = sleepDay %>%
  mutate_if(is.character, str_trim)

# Data is ready for Analysis!

# Determination of the number of unique participants in each data frame

n_distinct(dailyActivity$Id) # 33 unique participants
n_distinct(weightLog$Id) # 8 unique participants
n_distinct(sleepDay$Id) # 24 unique participants

# Determination of the number of observations in each data frame

nrow(dailyActivity) # 940 observations 
nrow(weightLog) # 67 observations
nrow(sleepDay) # 413 observations

# Quick summary statistics
dailyActivity %>% 
  select(TotalSteps,
         TotalDistance, 
         SedentaryMinutes) %>% 
  summary()

weightLog %>% 
  select(WeightKg,
         BMI) %>% 
  summary()

sleepDay %>% 
  select(TotalSleepRecords, 
         TotalMinutesAsleep,
         TotalTimeInBed) %>% 
  summary()

## Relationship between steps taken per day and sedentary minutes
dailyActivity %>% 
  filter(TotalSteps < 17500) %>% 
  ggplot() +
  geom_point(mapping=aes(x = TotalSteps, y = SedentaryMinutes), alpha=0.3, position = position_jitter()) +
  geom_smooth(mapping=aes(x = TotalSteps, y = SedentaryMinutes)) + stat_ellipse(mapping=aes(x = TotalSteps, y = SedentaryMinutes)) +
  labs(x = "Total Steps", y = "Sedentary Minutes", title="Steps taken per day vs Sedentary minutes", subtitle = "What relationship can we see here?") +
  annotate("segment", x=100, xend=5000, y=500, yend=1000, color = "blue", alpha=0.6, arrow=arrow()) +
  annotate("text", x=0, y=500, label = "Negative correlation") # There is a weak negative correlation between total steps taken and number of sedentary minutes
ggsave("steps_taken_vs_sedentary_minutes.png")

## Relationship between minutes asleep and time in bed;
ggplot(data = sleepDay) +
  geom_point(mapping=aes(x=TotalMinutesAsleep, y = TotalTimeInBed), alpha=0.3, position = position_jitter()) +
  geom_smooth(mapping=aes(x=TotalMinutesAsleep, y = TotalTimeInBed)) + 
  labs(x = "Total Minutes Asleep", y = "Total Time In Bed", title="Total minutes asleep vs Total time in bed", subtitle = "What relationship can we see here?") +
  annotate("segment", x=500, xend=400, y=250, yend=375, color = "blue", alpha=0.6, arrow=arrow()) +
  annotate("text", x=500, y=250, label = "Strong positive correlation") # There is a strong positive correlation between the total number of minutes asleep and the total number of minutes spent in bed.
ggsave("totalMinutesAsleep_vs_totalTimeInBed.png")

# Merging data sets together
combined_df = dailyActivity %>% 
  full_join(sleepDay, by="Id")

total_df = combined_df %>% 
  full_join(weightLog, by="Id")

n_distinct(combined_df$Id) # The number of unique participants is still 33 after merging both data sets as a result of the outer join. 

# Relationship between minutes asleep and number of steps;
ggplot(data = combined_df) + 
  geom_point(mapping=aes(x=TotalMinutesAsleep, y = TotalSteps), alpha=0.3, position = position_jitter()) +
  geom_smooth(mapping=aes(x=TotalMinutesAsleep, y = TotalSteps)) +
  labs(x = "Total Minutes Asleep", y = "Total Steps", title="Total minutes asleep vs Total steps", subtitle = "What relationship can we see here?") +
  annotate("text", x=400, y=30000, color = "blue", label = "No correlation") # There is almost no correlation between total number of minutes of sleep and the total steps taken per day. 
ggsave("totalMinutesAsleep_vs_totalSteps.png")

# Relationship between bmi and number of steps;
total_df$bmi_category = cut(total_df$BMI, breaks = c(-Inf, 18.5, 24.9, 29.9, Inf), labels = c("Underweight", "Normal Weight", "Overweight", "Obese"), right = FALSE)
average_steps = total_df %>% 
  group_by(bmi_category) %>% 
  summarise(Average_steps = mean(TotalSteps))

average_steps = average_steps %>% 
  filter(!is.na(bmi_category)) %>% 
           filter(!bmi_category == "Obese") # Observations for obesity were removed to ensure data fairness. Also, observation was just one and could be considered as an outlier.
ggplot(average_steps, aes(x=bmi_category, y = Average_steps), alpha=0.3, position = position_jitter()) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(x = "BMI category", y = "Average Steps per day", title="Average Steps by BMI category") +
  theme_minimal() # There is little variation in the number of steps with being normal weight or overweight.
ggsave("average_steps_by_bmi_category.png")



