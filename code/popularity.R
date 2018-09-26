# POPULARITY.R
#
# This script collects Google Trends data for each guest listed in guests.csv.
# The data are based on web search interest in the United States and are
# provided in weekly intervals over the past five years.
#
# Ben Davies
# September 2018


library(dplyr)
library(gtrendsR)
library(readr)

guests <- read_csv("data/guests.csv")


# Collect data
data_list <- list()
queries <- c("Joe Rogan", sort(unique(guests$guest_name)))
for (i in 1 : length(queries)) {
  cat(paste("Collecting data for query", i, "of", length(queries), "\n"))
  data_list[[i]] <- gtrends(queries[i], "US")[[1]]
}

# Tidy and export data
do.call(rbind, data_list) %>%
  mutate(date = as.Date(date),
         interest = as.numeric(hits),
         interest = replace(interest, is.na(interest), 0)) %>%
  select(date, keyword, interest) %>%
  write_csv("data/popularity.csv")
