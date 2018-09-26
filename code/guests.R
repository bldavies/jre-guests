# GUESTS.R
#
# This script generates a list of guests appearing in each episode of The Joe
# Rogan Experience listed in episodes.csv.
#
# Ben Davies
# September 2018


library(dplyr)
library(readr)
library(stringr)
library(tidyr)

episodes <- read_csv("data/episodes.csv")


# Generate guest list and make manual adjustments
guests <- episodes %>%
  rename(name = episode_title,
         number = episode_number) %>%
  select(number, name) %>%
  filter(number != 827) %>%
  mutate(name = sub(" &", ",", name),
         name = gsub("(.*Eleanor)(.*?)(*Kerrigan)", "\\1 \\3", name),
         name = gsub("(.*Joey)(.*?)(*Diaz)", "\\1 \\3", name),
         name = gsub("(.*?),(.*?)(Jr.)(.*?)", "\\1 Jr.\\4", name),
         name = gsub("Steve Rinella", "Steven Rinella", name),
         name = ifelse(number == 18, "Brian Redban", name),
         name = ifelse(number == 68, "Iliza Shlesinger", name),
         name = ifelse(number == 149, "Little Esther, Al Madrigal, Josh McDermitt, Brendon Walsh, Felicia Michaels, Brian Redban", name),  # "Live from the Icehouse"
         name = ifelse(number %in% c(171, 201, 254), "Everlast", name),
         name = ifelse(number %in% c(208, 323), "Rick Ross", name),
         name = ifelse(number %in% c(243, 299, 701), "Honey Honey", name),
         name = ifelse(number == 246, "Maynard James Keenan", name),
         name = ifelse(number == 305, "Bert Kreischer", name),
         name = ifelse(number == 313, "Gregg Hughes", name),
         name = ifelse(number == 340, "JD Kelley", name),
         name = ifelse(number == 489, "Liam Resnekov, Dylan Resnekov", name),
         name = ifelse(number == 508, "TJ Dillashaw, Duane Ludwig", name),
         name = ifelse(number %in% c(516, 521, 580, 696, 792), "Lewis Hilsenteger", name),  # "Lewis, from Unbox Therapy"
         name = ifelse(number == 517, "Crash from Float Lab", name),
         name = ifelse(number == 528, "Michael Stevens", name),
         name = ifelse(number == 530, "Vince Horn, Emily Horn", name),
         name = ifelse(number == 568, "Dr. Rhonda Patrick", name),
         name = ifelse(number == 586, "Tony Hinchcliffe, Sara Weinshenk, Kimberly Congdon", name),
         name = ifelse(number %in% c(614, 697), "Christopher Ryan", name),
         name = ifelse(number == 643, "Big Jay Oakerson", name),
         name = ifelse(number == 670, "Michael Wood Jr.", name),
         name = ifelse(number %in% c(682, 772, 1101), "Mark Bell, Chris Bell", name),
         name = ifelse(number == 706, "Brendan Schaub", name),
         name = ifelse(number == 797, "Alex Grey, Allyson Grey", name),
         name = ifelse(number == 807, "AJ Gentile, Gino Gentile", name),
         name = ifelse(number == 890, "Eddie Bravo, Brendan Schaub", name),
         name = ifelse(number == 893, "Joey Diaz, Eddie Bravo, Brendan Schaub", name),
         name = ifelse(number %in% c(894, 895), "Tom Segura, Bert Kreischer", name),
         name = ifelse(number == 896, "Young Jamie", name),
         name = ifelse(number == 902, "Jeff Ross, Greg Fitzsimmons, Andrew Santino", name),  # "Live Underground from The Comedy Store"
         name = ifelse(number == 916, "Eddie Bravo, Bryan Callen, Brendan Schaub", name),
         name = ifelse(number == 1097, "Big Jay Oakerson, Luis J. Gomez, Dave Smith", name)) %>%  # "Legion of Skanks"
  mutate(name = str_split(name, ",")) %>%
  unnest() %>%
  mutate(name = trimws(name)) %>%
  filter(name != "Joe Rogan",
         !(name == "Brian Redban" & number < 674))

# Export data
guests %>%
  rename(episode_number = number,
         guest_name = name) %>%
  write_csv("data/guests.csv")
