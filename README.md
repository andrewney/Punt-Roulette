# Punt-Roulette

## Overview
Punt Roulette is a data analysis project to create a predictive model for the outcome of NFL drives - specifically punts.      

## Data Analysis Method

## Inputs Used

## Inputs Unused

## Filters 

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
