# import libraries
library(tidyverse)
library(ggrepel)
library(ggimage)
library(nflfastR)
library(caret)
library(e1071)


# load data by NFL season from nflfastR
# future::plan("multisession")
# pbp21 <- load_pbp(c(2021))

# set the NFL week of interest
set_week = 5

# clean data, isolate plays that start a drive, and create new columns for the 2021 season data which is used as the data test 
pbp_2021 <- pbp21 %>%
  # make drive_start_yardline consistant with yardline_100 because it uses 'MID 50' and not '50' to refer to the 50 yardline
  mutate(
    drive_start_yard_line1 = case_when(
      drive_start_yard_line == '50' ~ 'MID 50',
      TRUE ~ drive_start_yard_line
    )
  ) %>%
  #add additional columns with binary or numerical variables
  mutate(first_play = if_else(yrdln == drive_start_yard_line1, 1, 0)) %>% 
  mutate(unique_play = paste(game_id, play_id, sep = "")) %>% 
  mutate(punt = if_else(fixed_drive_result == "Punt", 1,0)) %>% 
  mutate(home_has_ball = if_else(posteam == home_team,1,0)) %>%
  mutate(dome = if_else(roof == "dome",1, if_else(roof == "closed",1,0))) %>% 
  mutate(pos_from_punt = if_else(drive_start_transition == "PUNT",1,0)) %>% 
  mutate(pos_from_turnover = if_else(drive_start_transition == "INTERCEPTION",1,if_else(drive_start_transition == "FUMBLE",1,0))) %>% 
  mutate(total_points = total_home_score + total_away_score) %>%
  mutate(posteam_spread = if_else(home_has_ball == 1, spread_line*-1, spread_line)) %>% 
  mutate(time_under30 = if_else(half_seconds_remaining <= 30,1,0)) %>% 
  mutate(time_between30_60 = if_else(half_seconds_remaining >30 & half_seconds_remaining <= 60,1,0)) %>% 
  mutate(time_between60_90 = if_else(half_seconds_remaining >60 & half_seconds_remaining <= 90,1,0)) %>%
  mutate(time_between90_120 = if_else(half_seconds_remaining >90 & half_seconds_remaining <= 120,1,0)) %>%
  mutate(time_between120_150 = if_else(half_seconds_remaining >120 & half_seconds_remaining <= 150,1,0)) %>%
  mutate(time_between150_180 = if_else(half_seconds_remaining >150 & half_seconds_remaining <= 180,1,0)) %>%
  mutate(wp_abs = abs(vegas_wp-0.5)) %>% 
  #create unqiue key for the year in which the posession and defensive teams have the ball
  mutate(posteam_year = paste(posteam, season, sep = "")) %>% 
  mutate(defteam_year = paste(defteam, season, sep = "")) %>%
  # apply filters and select the variables for the table  
  filter(season_type == "REG", fixed_drive_result != "End of half", !is.na(posteam), posteam != "", first_play == 1, down == 1, ydstogo ==10, qb_kneel == 0, unique_play != "2015_08_NYG_NO5002", unique_play != "2015_15_ATL_JAX2249", unique_play != "2017_17_WAS_NYG2087", unique_play != "2018_16_JAX_MIA1858", unique_play != "2020_09_LV_LAC1872") %>%
  group_by(game_id, play_id) %>%
  select(posteam_year, defteam_year, desc, half_seconds_remaining, posteam_score, defteam_score, fixed_drive_result, week,  
         punt,
         vegas_wp,
         yardline_100,
         posteam_spread,
         total_line,
  ) 

# view table and save as a csv
# view(pbp_2021)
# write.csv(pbp_2021,"C:\\Users\\ney.andrew\\Documents\\R\\Excel\\Weekly Punting Data\\pbp_week3_data.csv", row.names = FALSE)



# create a separate table to calculate punt frequency and merge them with data test and data train
off_punt_percent <- pbp_2021 %>% 
  group_by(posteam_year) %>% 
  summarize(off_punt = mean(punt))
# view(off_punt_percent)

def_punt_percent <- pbp_2021 %>% 
  group_by(defteam_year) %>% 
  summarize(def_punt = mean(punt))
# view(def_punt_percent)

ytd_punt_percent <- off_punt_percent %>% 
  left_join(def_punt_percent, by = c('posteam_year' = 'defteam_year'))
# view(ytd_punt_percen
# write.csv(ytd_punt_percent,"C:\\Users\\ney.andrew\\Documents\\R\\Excel\\Weekly Punting Data\\ytd_punt_week4_data.csv", row.names = FALSE)





# adding additional filters after the creation of ytd_punt_percent
pbp_2021 <- pbp_2021 %>% 
  filter(half_seconds_remaining > 120) %>% 
  filter(posteam_spread < -2) %>% 
  filter(week == set_week) 





# whole new dataset for finding epa (offensive and defensive efficiency)
pbp_epa21 <- pbp21 %>%
  filter(week < set_week) %>% 
  filter(rush == 1 | pass == 1, season_type == "REG", !is.na(epa), !is.na(posteam), posteam != "") %>%
  mutate(posteam_year = paste(posteam, season, sep = "")) %>% 
  mutate(defteam_year = paste(defteam, season, sep = "")) %>%
  select(posteam, pass, defteam, epa, season, posteam_year, defteam_year)
# head(pbp_epa21)

# put the offensive numbers in one table
offense21 <- pbp_epa21 %>% 
  group_by(posteam_year, pass) %>% 
  summarize(epa = mean(epa)) %>% 
  pivot_wider(names_from = pass, values_from = epa) %>% 
  rename(off_pass_epa = "1", off_rush_epa = "0")
# view(offense21)

# put the defensive in another table  
defense21 <- pbp_epa21 %>% 
  group_by(defteam_year, pass) %>% 
  summarize(epa = mean(epa)) %>% 
  pivot_wider(names_from = pass, values_from = epa) %>% 
  rename(def_pass_epa = "1", def_rush_epa = "0") 
# view(defense21)

# put offense and defense into a table together strictly for saving to a csv
ytd_epa <- offense21 %>% 
  left_join(defense21, by = c('posteam_year' = 'defteam_year'))
# view(ytd_epa)  
# write.csv(ytd_epa,"C:\\Users\\ney.andrew\\Documents\\R\\Excel\\Weekly EPA Data\\ytd_epa_week4_data.csv", row.names = FALSE)


# bring both epa data and punt percent daat together and into the larger table
pbp_epa_2021 <- pbp_2021 %>% 
  left_join(offense21, by = c('posteam_year' = 'posteam_year')) %>%
  left_join(defense21, by = c('defteam_year' = 'defteam_year')) %>% 
  left_join(ytd_punt_percent, by = c('posteam_year' = 'posteam_year')) %>% 
  group_by(game_id, play_id) 

# view(pbp_epa_2021)




# import 2018-2020 Historic Data
# future::plan("multisession")
# pbp <- load_pbp(c(2018:2020))

# create an identical table to the 2021 data, which will be used as the data train
pbp_2018_2020 <- pbp %>%
  # make drive start yardline consistant with yardline_100
  mutate(
    drive_start_yard_line1 = case_when(
      drive_start_yard_line == '50' ~ 'MID 50',
      TRUE ~ drive_start_yard_line
    )
  ) %>%
  mutate(first_play = if_else(yrdln == drive_start_yard_line1, 1, 0)) %>% 
  mutate(unique_play = paste(game_id, play_id, sep = "")) %>% 
  mutate(punt = if_else(fixed_drive_result == "Punt", 1,0)) %>% 
  mutate(home_has_ball = if_else(posteam == home_team,1,0)) %>%
  mutate(dome = if_else(roof == "dome",1, if_else(roof == "closed",1,0))) %>% 
  mutate(pos_from_punt = if_else(drive_start_transition == "PUNT",1,0)) %>% 
  mutate(pos_from_turnover = if_else(drive_start_transition == "INTERCEPTION",1,if_else(drive_start_transition == "FUMBLE",1,0))) %>% 
  mutate(total_points = total_home_score + total_away_score) %>%
  mutate(posteam_spread = if_else(home_has_ball == 1, spread_line*-1, spread_line)) %>% 
  mutate(time_under30 = if_else(half_seconds_remaining <= 30,1,0)) %>% 
  mutate(time_between30_60 = if_else(half_seconds_remaining >30 & half_seconds_remaining <= 60,1,0)) %>% 
  mutate(time_between60_90 = if_else(half_seconds_remaining >60 & half_seconds_remaining <= 90,1,0)) %>%
  mutate(time_between90_120 = if_else(half_seconds_remaining >90 & half_seconds_remaining <= 120,1,0)) %>%
  mutate(time_between120_150 = if_else(half_seconds_remaining >120 & half_seconds_remaining <= 150,1,0)) %>%
  mutate(time_between150_180 = if_else(half_seconds_remaining >150 & half_seconds_remaining <= 180,1,0)) %>%
  mutate(wp_abs = abs(vegas_wp-0.5)) %>% 
  mutate(posteam_year = paste(posteam, season, sep = "")) %>% 
  mutate(defteam_year = paste(defteam, season, sep = "")) %>%
  filter(season_type == "REG", fixed_drive_result != "End of half", !is.na(posteam), posteam != "", first_play == 1, down == 1, ydstogo ==10, qb_kneel == 0, unique_play != "2015_08_NYG_NO5002", unique_play != "2015_15_ATL_JAX2249", unique_play != "2017_17_WAS_NYG2087", unique_play != "2018_16_JAX_MIA1858", unique_play != "2020_09_LV_LAC1872") %>%
  filter(half_seconds_remaining > 120) %>% 
  filter(posteam_spread < -2) %>%
  group_by(game_id, play_id) %>%
  select(posteam_year, defteam_year, desc, game_seconds_remaining, posteam_score, defteam_score,fixed_drive_result, wp_abs,  
         punt,
         vegas_wp,
         yardline_100,
         posteam_spread,
         total_line
  ) 
# view(pbp_2018_2020)



# whole new dataset for finding epa (offensive and defensive efficiency)
pbp_epa <- pbp %>%
  filter(rush == 1 | pass == 1, season_type == "REG", !is.na(epa), !is.na(posteam), posteam != "") %>%
  mutate(posteam_year = paste(posteam, season, sep = "")) %>% 
  mutate(defteam_year = paste(defteam, season, sep = "")) %>%
  select(posteam, pass, defteam, epa, season, posteam_year, defteam_year)
# head(out2)

# put the offensive numbers in one table
offense <- pbp_epa %>% 
  group_by(posteam_year, pass) %>% 
  summarize(epa = mean(epa)) %>% 
  pivot_wider(names_from = pass, values_from = epa) %>% 
  rename(off_pass_epa = "1", off_rush_epa = "0")
# view(offense)

# put the defensive in another table  
defense <- pbp_epa %>% 
  group_by(defteam_year, pass) %>% 
  summarize(epa = mean(epa)) %>% 
  pivot_wider(names_from = pass, values_from = epa) %>% 
  rename(def_pass_epa = "1", def_rush_epa = "0") 
# view(defense)

# bring both offense and defense together and into the larger table
pbp_epa_2018_2020 <- pbp_2018_2020 %>% 
  left_join(offense, by = c('posteam_year' = 'posteam_year')) %>%
  left_join(defense, by = c('defteam_year' = 'defteam_year')) %>% 
  group_by(game_id, play_id) 

# view(pbp_epa_2018_2020)




# Selecting the last 17 columns to use as predictors for both the 2021 data (data test) and historic data (data train)
# Notation is selecting [all rows, removing columns 1 and 2 bc they were only used for groupby]
punt_predictors_2021 = pbp_epa_2021[,-c(1,2)]
punt_predictors_hist = pbp_epa_2018_2020[,-c(1,2)]

# view(punt_predictors_2021)

# Selecting only rows where the yardline is greater than 74
punt_predictors_2021 = punt_predictors_2021[punt_predictors_2021$yardline_100 > 74,]
punt_predictors_hist = punt_predictors_hist[punt_predictors_hist$yardline_100 > 74,]

# summary(punt_predictors_2021)
# summary(punt_predictors_hist)





# put the 2021 data in for data test and the 2018-2020 historical data as the data train
set.seed(100)
# data_test_rows = sample(nrow(punt_predictors_hist), 0.2*nrow(punt_predictors_hist))
data_test_desc = punt_predictors_2021
# data_train_desc = punt_predictors_hist[-data_test_rows, ]
data_train_desc = punt_predictors_hist

# must get rid of the teams, descriptions (stuff that arent predictors) bc they cant be used in the model
# 1=posteam_year, 2=defteam_year, 3=desc, 4=game_sec_rem, 5=posteam_score, 6=defteam_score, 7=drive_result, 8=wp_abs 9=punt, 10=vegas_wp, 11=yardline, 12=spread, 13=o/u, 14-17=epa, 18-off_punt, 19-def_punt
# note that in season punt% can't be used
data_test = data_test_desc[,-c(1:7,8,14,16,18,19)]
data_train = data_train_desc[,-c(1:7,8,14,16)]


# for the logistic regression I can't have punt no punt in there, it has to be binary
data_train_glm <- data_train
data_test_glm <- data_test

data_test$punt[data_test$punt == 1] <- "Punt"
data_test$punt[data_test$punt == 0] <- "No_Punt"
data_train$punt[data_train$punt == 1] <- "Punt"
data_train$punt[data_train$punt == 0] <- "No_Punt"


# running the k fold validation to determine which are the best variables for predicting a punt outcome
ctrlSpecs <- trainControl(method ="cv", number=10, 
                          savePredictions = "all", classProbs = TRUE)
set.seed(100)
model_k <- train(punt ~ ., family = 'binomial', data = data_train, 
                 method = "glm", trControl = ctrlSpecs)

# viewing results
summary(model_k)
print(model_k)

#variable importance ranked
varImp(model_k)



# predict model outcome using from data_train applied to data_test
prediction_k <- predict(model_k, newdata = data_test)

#create confusion matrix
confusionMatrix(data = prediction_k, as.factor(data_test$punt))






# combine the prediction punt and actual punts into one table called plot and added a binary indicator for the following
plot <- cbind(prediction_k, data_test_desc) %>%
  mutate(punt_actual = if_else(punt == "1","Punt", "No Punt")) %>% 
  mutate(predicted_punt = if_else(prediction_k == "Punt",1,0)) %>% 
  mutate(did_punt = if_else(punt_actual == "Punt",1,0)) %>% 
  mutate(predict_and_did_punt = ifelse(prediction_k == "Punt" & punt_actual == "Punt",1,0))
# view(plot)
# write.csv(plot,"C:\\Users\\ney.andrew\\Documents\\R\\Excel\\Weekly Data\\low_spread_data.csv", row.names = FALSE)


# create new columns based on the success of the model
plot_wp_avg <- plot %>% 
  mutate(vegas_wp_round = round(vegas_wp, digits=1)) %>% 
  group_by(vegas_wp_round)
plot_wp_avg1 <- plot_wp_avg %>% 
  group_by(vegas_wp_round) %>% 
  summarize(did_punt_avg = mean(did_punt))  
plot_wp_avg2 <- plot_wp_avg %>% 
  group_by(vegas_wp_round) %>%
  summarize(predicted_punt_avg = mean(predicted_punt))
plot_wp_avg3 <- plot_wp_avg %>% 
  group_by(vegas_wp_round) %>%
  summarize(predict_and_did_punt_avg = mean(predict_and_did_punt))
plot_wp_avg <- merge(plot_wp_avg1, plot_wp_avg2, by = "vegas_wp_round") %>% 
  left_join(plot_wp_avg3, by = c('vegas_wp_round' = 'vegas_wp_round')) 

# chart to graph the punt rate based on win probability, red being the predicted punt rate and blue being the actual
plot(plot_wp_avg$vegas_wp_round, plot_wp_avg$predicted_punt_avg, col="red", lty=1,xlim=c(0,1.2), ylim=c(0,1.0), main='Red = predicted punt %, Blue = real punt %')
points(plot_wp_avg$vegas_wp_round, plot_wp_avg$did_punt_avg, col="blue",lty=2)




# graph where each point is a different drive start, black means the team did not punt, blue they did punt and the y axis was the win probability at the time
predicted_data <- plot[order(plot$vegas_wp, decreasing = FALSE),] %>% 
  filter(prediction_k == "Punt")
predicted_data$rank <- 1:nrow(predicted_data)
ggplot(data=predicted_data, aes(x=rank, y=vegas_wp))+
  geom_point(aes(color=did_punt),alpha=1, shape=4, stroke=2)+
  xlab("Index")+
  ylab("Vegas Win Probability")
# pred = predict(glm_punt,data_test_glm,type="response")




