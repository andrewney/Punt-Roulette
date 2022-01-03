## creating plots

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
