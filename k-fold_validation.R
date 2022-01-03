## Running the k-fold validation based on the data test and data train created in "data_cleaning.R"

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




