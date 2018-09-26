# EPISODES.R
#
# This script scrapes podcasts.joerogan.net for the number, date and title of
# regular episodes of The Joe Rogan Experience.
#
# Ben Davies
# September 2018


library(dplyr)
library(httr)
library(readr)
library(rvest)

DOMAIN <- "http://podcasts.joerogan.net/"


## EXTRACT RAW METADATA

# Get number of pages
front_page <- GET(DOMAIN)
num_pages <- front_page %>%
  content() %>%
  html_nodes("li:nth-child(5) .page-numbers") %>%
  html_text() %>%
  as.numeric()

# Iterate over pages
data_list <- list()
for (page_num in 1 : num_pages) {
  
  # Send request to update table
  page <- GET(url = paste0(DOMAIN, "podcasts/page/", page_num),
              add_headers(
                Referer = DOMAIN,
                `X-Requested-With` = "XMLHttpRequest"
              ),
              query = "load",
              verbose())
  
  # Extract HTML content
  page_content <- content(page)
  
  # Extract episode dates
  dates <- page_content %>%
    html_nodes(".podcast-date h3") %>%
    html_text() %>%
    as.Date("%m.%d.%y")
  
  # Extract episode numbers
  numbers <- page_content %>%
    html_nodes(".episode-num") %>%
    html_text() %>%
    substr(2, length(.)) %>%
    as.numeric()
  
  # Extract episode titles
  titles <- page_content %>%
    html_nodes(".ajax-permalink h3") %>%
    html_text()
  
  # Extract episode descriptions
  descriptions <- page_content %>%
    html_nodes(".podcast-content") %>%
    html_text()
  
  # Generate tibble with page data
  page_data <- tibble(date = dates,
                      number = numbers,
                      title = titles,
                      description = descriptions)
  
  # Add page data to master list
  data_list[[page_num]] <- page_data
}


## CLEAN AND EXPORT METADATA

# Initialise episode identification
episodes <- do.call(rbind, data_list) %>%
  mutate(row_index = row_number(),
         number = ifelse(row_index == n(), 1, number),
         id = as.integer(sub(".*# *(.*?) *\\..*", "\\1", description)))

# Identify MMA shows, fight companions and JRQE episodes
mma_episodes <- episodes %>% filter(grepl("MMA", title))
fight_companions <- episodes %>% filter(substr(title, 7, 15) == "Companion")  # Excludes #706
jrqe_episodes <- episodes %>% filter(grepl("JRQE", description))

# Identify regular episodes, and fix missing, incorrect and duplicate numbers
regular_episodes <- episodes %>%
  mutate(number = ifelse(is.na(number), id, number)) %>%
  filter(!row_index %in% mma_episodes$row_index,
         !row_index %in% fight_companions$row_index,
         !row_index %in% jrqe_episodes$row_index,
         !(is.na(number) & is.na(id))) %>%
  mutate(number = ifelse(id %in% c(677, 1117), id, number),
         number = ifelse(number == 173 & title == "Bryan Callen", 172, number),
         number = ifelse(number == 1037 & title != "Chris Kresser", 1036, number)) %>%
  group_by(number) %>%
  filter(n() - row_number() == 0) %>%  # Remove Part 2 of #515, #701 and #706
  ungroup()

# Check that all regular episodes are included
num_episodes <- max(episodes$number, na.rm = TRUE)
length(setdiff(1 : num_episodes, regular_episodes$number)) == 0

# Convert non-ASCII characters and export regular episode metadata
regular_episodes %>%
  mutate(title = ifelse(number == 372, "Mariana van Zeller", title),
         title = iconv(title, "", "ASCII", sub = "byte"),
         title = sub("<c3><b1>", "n", title),
         title = sub("<e2><80><93>", "-", title),
         title = sub("<e2><80><99>", "\'", title),
         title = sub("<e2><80><9c>", "\"", title),
         title = sub("<e2><80><9d>", "\"", title)) %>%
  select(number, date, title) %>%
  setNames(paste0("episode_", names(.))) %>%
  write_csv("data/episodes.csv")
