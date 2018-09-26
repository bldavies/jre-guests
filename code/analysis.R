# ANALYSIS.R
#
# This script generates the figures and table used in my blog post.
#
# Ben Davies
# September 2018


library(dplyr)
library(ggplot2)
library(lubridate)
library(readr)
library(tidyr)
library(zoo)

episodes <- read_csv("data/episodes.csv")
guests <- read_csv("data/guests.csv")
popularity <- read_csv("data/popularity.csv")


# Plot annual episode, guest and first appearance counts
guests %>%
  left_join(episodes) %>%
  mutate(episode_year = floor_date(episode_date, "year")) %>%
  filter(episode_year >= as.POSIXct("2010-01-01")) %>%
  group_by(guest_name) %>%
  mutate(first_appearance = episode_number == min(episode_number)) %>%
  group_by(episode_year) %>%
  summarise(num_episodes = n_distinct(episode_number),
            num_guests = n_distinct(guest_name),
            num_new_guests = sum(first_appearance)) %>%
  ungroup() %>%
  gather(key, value, -episode_year) %>%
  ggplot(aes(episode_year, value, fill = key)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Annual JRE episode, guest and first appearance counts") +
  scale_fill_brewer(labels = c("Episodes", "Unique guests", "First appearances"), palette = "Set1") +
  theme_light() +
  theme(axis.title = element_blank(),
        legend.position = "bottom",
        legend.title = element_blank(),
        plot.title = element_text(hjust = 0.5))
ggsave("figures/annual-counts.svg", width = 8, height = 4.5)


# Plot estimated popularity series for Joe Rogan
popularity %>%
  filter(keyword == "Joe Rogan") %>%
  ggplot(aes(date, interest)) +
  geom_line() +
  labs(y = "Search interest",
       title = "Web search interest for the phrase \"Joe Rogan\"") +
  theme_light() +
  theme(axis.title.x = element_blank(),
        plot.title = element_text(hjust = 0.5))
ggsave("figures/joe-rogan-popularity.svg", width = 8, height = 4.5)


# Identify weeks in which guests appeared
appearances <- episodes %>%
  left_join(guests) %>%
  mutate(episode_week = floor_date(episode_date, "week", week_start = 6)) %>%
  group_by(guest_name, episode_week, episode_number) %>%
  summarise(appears = TRUE) %>%
  ungroup()

# Plot actual, moving average and demaned popularity series for Dave Rubin
name <- "Dave Rubin"
popularity %>%
  filter(keyword == name) %>%
  mutate(ma = rollmean(interest, 7, fill = NA),
         dm = interest - ma) %>%
  gather(key, value, -date, -keyword) %>%
  mutate(key = ifelse(key == "ma", "Moving average", ifelse(key == "dm", "Demeaned", "Actual")),
         key = factor(key, levels = c("Actual", "Moving average", "Demeaned")),
         facet = key == "Demeaned") %>%
  ggplot(aes(date, value, col = key)) +
  geom_line() +
  geom_vline(data = filter(appearances, guest_name == name), aes(xintercept = episode_week), col = "grey50", lty = 2) +
  facet_grid(key ~ .) +
  labs(y = "Search interest",
       title = "Web search interest for the phrase \"Dave Rubin\"",
       col = "Series") +
  scale_colour_brewer(palette = "Set1") +
  theme_light() +
  theme(axis.title.x = element_blank(),
        legend.position = "bottom",
        legend.title = element_blank(),
        plot.title = element_text(hjust = 0.5),
        strip.background = element_blank(),
        strip.text = element_blank())
ggsave("figures/dave-rubin-popularity.svg", width = 8, height = 4.5)

# Plot distributions of standardised demeaned search interest
descriptions <- c("Two weeks before appearance",
                  "One week before appearance",
                  "Week of appearance",
                  "One week after appearance",
                  "Two weeks after appearance",
                  "Three weeks after appearance")
popularity %>%
  group_by(keyword) %>%
  mutate(z_lag_0 = scale(interest - rollmean(interest, 7, fill = NA))) %>%
  ungroup() %>%
  mutate(z_lag_2 = lag(z_lag_0, 2),
         z_lag_1 = lag(z_lag_0),
         z_lead_1 = lead(z_lag_0),
         z_lead_2 = lead(z_lag_0, 2),
         z_lead_3 = lead(z_lag_0, 3)) %>%
  left_join(appearances, by = c("keyword" = "guest_name", "date" = "episode_week")) %>%
  filter(appears) %>%
  gather(key, value, starts_with("z")) %>%
  separate(key, c("key", "suffix", "order")) %>%
  mutate(order = as.integer(order),
         order = ifelse(suffix == "lag", -order, order),
         description = descriptions[order + 3],
         description = factor(description, levels = descriptions)) %>%
  ggplot() +
  geom_vline(aes(xintercept = 0), col = "grey50") +
  geom_density(aes(value, fill = description)) +
  facet_wrap(~ description) +
  labs(x = "Standardised demeaned search interest",
       y = "Probability density",
       title = "Distributions of standardised demeaned search interest near JRE guest appearances") +
  scale_fill_brewer(palette = "Set1") +
  theme_light() +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5),
        strip.background = element_blank(),
        strip.text = element_text(colour = "black"))
ggsave("figures/densities.svg", width = 8, height = 4)


# Define function for implementing real-time detection algorithm
# See https://stackoverflow.com/questions/22583391/peak-signal-detection-in-realtime-timeseries-data/22640362#22640362
realtime_spikes <- function (series, lag, threshold, influence) {
  signal <- rep(0, length(series))
  filter <- series[0 : lag]
  filter_mean <- NULL
  filter_sd <- NULL
  filter_mean[lag] <- mean(filter)
  filter_sd[lag] <- sd(filter)
  for (obs in (lag + 1) : length(series)) {
    if (abs(series[obs] - filter_mean[obs - 1]) > threshold * filter_sd[obs - 1]) {
      if (series[obs] > filter_mean[obs - 1]) {
        signal[obs] <- 1
      } else {
        signal[obs] <- -1
      }
      filter[obs] <- influence * series[obs] + (1 - influence) * filter[obs - 1]
    } else {
      signal[obs] <- 0
      filter[obs] <- series[obs]
    }
    filter_mean[obs] <- mean(filter[(obs - lag) : obs])
    filter_sd[obs] <- sd(filter[(obs - lag) : obs])
  }
  return (tibble(signal = signal, filter_mean = filter_mean, filter_sd = filter_sd))
}

# Apply real-time detection algorithm to estimated popularity data
keywords <- sort(unique(popularity$keyword))
lags <- c(3, 6, 9, 12)
thresholds <- c(1, 2, 3, 4)
influence <- 0.5
data_list <- list()
for (i in 1 : length(keywords)) {
  cat(paste("Computing data for keyword", i, "of", length(keywords), "\n"))
  for (j in 1 : length(lags)) {
    for (k in 1 : length(thresholds)) {
      idx <- (i - 1) * length(lags) * length(thresholds) + (j - 1) * length(thresholds) + k
      keyword_popularity <- popularity %>% filter(keyword == keywords[i])
      data_list[[idx]] <- realtime_spikes(keyword_popularity$interest, lags[j], thresholds[k], influence)
      data_list[[idx]]$date <- keyword_popularity$date
      data_list[[idx]]$keyword <- keywords[i]
      data_list[[idx]]$lag <- lags[j]
      data_list[[idx]]$threshold <- thresholds[k]
      data_list[[idx]]$influence <- influence
    }
  }
}
algorithm_data <- do.call(rbind, data_list)

# Plot actual, filtering and signal series for Dave Rubin
algorithm_data %>%
  filter(keyword == name,
         lag == 12,
         threshold == 2) %>%
  left_join(popularity) %>%
  mutate(filter_ub = filter_mean + threshold * filter_sd,
         filter_lb = filter_mean - threshold * filter_sd) %>%
  ggplot(aes(date)) +
  geom_ribbon(aes(ymin = filter_lb, ymax = filter_ub), fill = "grey50", alpha = 0.25) +
  geom_line(aes(y = interest, col = "Actual")) +
  geom_line(aes(y = filter_mean, col = "Filtering mean")) +
  geom_line(aes(y = filter_ub, col = "Filtering threshold")) +
  geom_line(aes(y = filter_lb, col = "Filtering threshold")) +
  geom_line(aes(y = 10 * signal - 25, col = "Signal")) +
  geom_vline(data = filter(appearances, guest_name == name), aes(xintercept = episode_week), col = "grey50", lty = 2) +
  labs(y = "Search interest",
       title = "Web search interest for the phrase \"Dave Rubin\" and associated real-time spike signal",
       col = "Series") +
  scale_colour_brewer(palette = "Set1") +
  scale_y_continuous(breaks = c(-25, 0, 25, 50, 75, 100), labels = c("", 0, 25, 50, 75, 100)) +
  theme_light() +
  theme(axis.title.x = element_blank(),
        legend.position = "bottom",
        legend.title = element_blank(),
        plot.title = element_text(hjust = 0.5))
ggsave("figures/dave-rubin-signal.svg", width = 8, height = 4.5)

# Tabulate spike detection rates
algorithm_data %>%
  left_join(appearances, by = c("keyword" = "guest_name", "date" = "episode_week")) %>%
  group_by(keyword) %>%
  mutate(detected = (signal == 1) | (lead(signal) == 1)) %>%
  ungroup() %>%
  filter(appears) %>%
  group_by(lag, threshold) %>%
  summarise(rate = sum(appears & detected) / sum(appears)) %>%
  ungroup() %>%
  spread(lag, rate) %>%
  mutate_if(is.numeric, funs(round(., 3))) %>%
  write_csv("tables/detection-rates.csv")
