# Run the following script after each NFL week has concluded to get the data on the conditions prior to each start, each team's punt percentage, and each team's offensive and defensive efficiency

library(tidyverse)
library(ggrepel)
library(ggimage)
library(nflfastR)
library(caret)
library(e1071)


#### 2021 Data #####
 future::plan("multisession")
 pbp21 <- load_pbp(c(2021))

week_just_passed =16


# loading drive start data wihtout additional filters other than blank drives
pbp_2021_weekly <- pbp21 %>%
  # make drive start yardline consistant with yardline_100
  mutate(
    drive_start_yard_line1 = case_when(
      drive_start_yard_line == '50' ~ 'MID 50',
      TRUE ~ drive_start_yard_line
    )
  ) %>%
  #add additional tables
  mutate(first_play = if_else(yrdln == drive_start_yard_line1, 1, 0)) %>% 
  mutate(unique_play = paste(game_id, play_id, sep = "")) %>% 
  mutate(punt = if_else(fixed_drive_result == "Punt", 1,0)) %>% 
  mutate(home_has_ball = if_else(posteam == home_team,1,0)) %>%
  mutate(dome = if_else(roof == "dome",1, if_else(roof == "closed",1,0))) %>% 
  # mutate(posteam_opening_kickoff = if_else(home_has_ball == 1 & home_opening_kickoff ==1, 1, if_else(home_has_ball == 0 & home_opening_kickoff ==0, 1,0))) %>% 
  mutate(pos_from_punt = if_else(drive_start_transition == "PUNT",1,0)) %>% 
  # mutate(pos_from_kickoff = if_else(drive_start_transition == "KICKOFF",1,0)) %>% 
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
  #create concatinated posteam year and defteam year
  mutate(posteam_year = paste(posteam, season, sep = "")) %>% 
  mutate(defteam_year = paste(defteam, season, sep = "")) %>%
  # apply filters and select the variables for the table  
  filter(season_type == "REG", fixed_drive_result != "End of half", !is.na(posteam), posteam != "", first_play == 1, down == 1, ydstogo ==10, qb_kneel == 0, unique_play != "2015_08_NYG_NO5002", unique_play != "2015_15_ATL_JAX2249", unique_play != "2017_17_WAS_NYG2087", unique_play != "2018_16_JAX_MIA1858", unique_play != "2020_09_LV_LAC1872") %>%
  group_by(game_id, play_id) %>%
  select(posteam_year, defteam_year, desc,game_seconds_remaining, week, posteam_score, defteam_score, fixed_drive_result, half_seconds_remaining,  
         punt,
         vegas_wp,
         yardline_100,
         posteam_spread,
         total_line,
  ) 

# view(pbp_2021)




# create a separate table to calculate punt for off and def % as they started the week before

off_punt_percent <- pbp_2021_weekly %>% 
  filter(week < week_just_passed) %>% 
  group_by(posteam_year) %>% 
  summarize(off_punt = mean(punt))
# view(off_punt_percent)

def_punt_percent <- pbp_2021_weekly %>% 
  filter(week < week_just_passed) %>% 
  group_by(defteam_year) %>% 
  summarize(def_punt = mean(punt))
# view(def_punt_percent)

ytd_punt_percent <- off_punt_percent %>% 
  left_join(def_punt_percent, by = c('posteam_year' = 'defteam_year'))

# view(ytd_punt_percent)  
write.csv(ytd_punt_percent,"C:\\Users\\ney.andrew\\Documents\\R\\Excel\\Weekly Punting Data\\punt_percent_before_week13.csv", row.names = FALSE)




# create a table for efficiency as it was the week before the week that just passed

pbp_epa21 <- pbp21 %>%
  filter(rush == 1 | pass == 1, season_type == "REG", !is.na(epa), !is.na(posteam), posteam != "") %>%
  filter(week < week_just_passed) %>% 
  mutate(posteam_year = paste(posteam, season, sep = "")) %>% 
  mutate(defteam_year = paste(defteam, season, sep = "")) %>%
  select(posteam, pass, defteam, epa, season, posteam_year, defteam_year)
# head(pbp_epa21)

# throw the offensive numbers in one table
offense21 <- pbp_epa21 %>% 
  group_by(posteam_year, pass) %>% 
  summarize(epa = mean(epa)) %>% 
  pivot_wider(names_from = pass, values_from = epa) %>% 
  rename(off_pass_epa = "1", off_rush_epa = "0")
# view(offense21)

# throw the defensive in another table  
defense21 <- pbp_epa21 %>% 
  group_by(defteam_year, pass) %>% 
  summarize(epa = mean(epa)) %>% 
  pivot_wider(names_from = pass, values_from = epa) %>% 
  rename(def_pass_epa = "1", def_rush_epa = "0") 
# view(defense21)

# throw offense and defense into a table together
ytd_epa <- offense21 %>% 
  left_join(defense21, by = c('posteam_year' = 'defteam_year'))
# view(ytd_epa)  
write.csv(ytd_epa,"C:\\Users\\ney.andrew\\Documents\\R\\Excel\\Weekly EPA Data\\ytd_epa_week13_data.csv", row.names = FALSE)



# putting back in filters that can't be in punt or epa tables
pbp_2021_weekly1 <- pbp_2021_weekly %>% 
  filter(half_seconds_remaining > 120) %>% 
  filter(yardline_100 >74) %>% 
  filter(week == week_just_passed)

# bring both punts and epa into the drive start table and filter out what I dont need
pbp_2021_weekly1 <- pbp_2021_weekly1 %>% 
  left_join(offense21, by = c('posteam_year' = 'posteam_year')) %>%
  left_join(defense21, by = c('defteam_year' = 'defteam_year')) %>% 
  left_join(ytd_punt_percent, by = c('posteam_year' = 'posteam_year')) %>% 
  group_by(game_id, play_id) 
pbp_2021_weekly1 <- pbp_2021_weekly1[,-c(1,2,11)]




# view(pbp_2021_weekly1)
write.csv(pbp_2021_weekly1,"C:\\Users\\ney.andrew\\Documents\\R\\Excel\\Weekly Drive Start Data\\week12_data.csv", row.names = FALSE)



