# Punt-Roulette

## Overview
Punt Roulette is a data analysis project to create a predictive model for the outcome of NFL drives - specifically punts.      

## Data Analysis Method
The dataset I used from nflfastR, provides datapoints from every NFL play dating back to 1999, but the NFL moved the starting yardline following a touchback to the 25 yardline following the 2017 season.  Consequently, I used data from the 2018-2020 season as the data train and 2021 data for the data test in the logistic regression.  But since the data on each NFL play came with 400+ data points, it was necessary to narrow down to find which would be the best predictive variables for a punt.  To selecting predictive variables, I used a k-fold validation which runs a generalized linear regression and ranks the predictive variables by how much they influence the accuracy to predict a punt, in this case.  I used a combination of personal football intutiton as well as popular literature on regression models of the NFL for my initial list of predictive variables.


## Predictive Variables Used
Of all the predictive variables tried, these were the only ones that had a significant impact on the model's ability to predict a punt
- The win probability (as calculated by a sports book) of the team with the ball
- The yardline that the drive begins on
- The spread on the game (as calculated by a sports book)
- The over/ under on the game (as calculated by a sports book)
- The offense's passing efficiency
- The defense's passing efficiency


## Results: Weeks 1-16

The model predicting that there would not be a punt is not particularly exciting given that there are multiple other outcomes (touchdown, turnover, field goal, etc.).  A good metric for this model is to focus on when the model predicts a punt.  Sports books with live betting odds, sometimes allow you to bet the outcome of the next drive (including a punt), which gives a good baseline for comparing the model against an industry that's profit depends on the accuracy of its predictions.  For the sake of simplicity we will use a standard -110 (American betting odds for a 50:50 outcome), which means you wager $110 to win $100 each time the model predicts a punt.  Doing this for each drive over the 2021 NFL season (through week 16) would yield a profit of $3530.  A line of -110 is not always the case since odds makers also adjust for scenarios in which a punt is more likely, but it does show the model can predict a punt more often than not.

Definitions:
- correct_no_punt: Model correctly predicted that there would be no punt
- missed_punt: Model predicted that there would be no punt but the team punted
- incorrect_punt: Model predicted a punt but the team did not punt
- correct_punt: Model correctly predicted a punt
- profit: Profit if a wager was placed $110 to win $100 each time the model predicted a punt

|        | correct_no_punt | missed_punt | incorrect_punt | correct_punt | profit  |
|--------|-----------------|-------------|----------------|--------------|---------|
| week1  | 50              | 21          | 12             | 22           | $880    |
| week2  | 52              | 24          | 16             | 16           | -$160   |
| week3  | 32              | 35          | 8              | 20           | $1,120  |
| week4  | 33              | 19          | 13             | 16           | $170    |
| week5  | 45              | 25          | 24             | 14           | -$1,240 |
| week6  | 26              | 13          | 15             | 13           | -$350   |
| week7  | 37              | 34          | 9              | 11           | $110    |
| week8  | 39              | 22          | 15             | 18           | $150    |
| week9  | 23              | 13          | 17             | 26           | $730    |
| week10 | 21              | 16          | 11             | 21           | $890    |
| week11 | 25              | 26          | 10             | 21           | $1,000  |
| week12 | 31              | 25          | 12             | 13           | -$20    |
| week13 | 29              | 28          | 13             | 17           | $270    |
| week14 | 33              | 32          | 12             | 17           | $380    |
| week15 | 15              | 10          | 18             | 26           | $620    |
| week16 | 30              | 21          | 22             | 14           | -$1,020 |
| Total  | 521             | 364         | 227            | 285          | $3,530  |


CHART


## Data Source
nflfastR - Website - Github
