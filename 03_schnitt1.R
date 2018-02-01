# 02 schnitt1.R: Berechnet die Durchschnitte

# setwd('~/Git/signalundrauschen')

library(dplyr)
library(lubridate)
library(tidyr)

df <- read.csv('daten/umfragedaten.csv', stringsAsFactors = F) %>% tbl_df()

df$monat <- month(df$datum) # Monat der Umfrage

df$woche <- week(df$datum) # Woche der Umfrage

# Monatlicher Durchschnitt

monatsschnitt <-
  df %>% filter(!is.na(jahr), !is.na(monat)) %>%
  group_by(jahr, monat, partei) %>%
  summarise(stimmanteil = round(mean(stimmanteil, na.rm = T), 1)) %>%
  filter(!is.na(stimmanteil)) %>%
  mutate(date = paste(jahr, monat, '01', sep = '-'),
         partei = dplyr::recode(partei, afd = 'AfD', cdu_csu = 'CDU/CSU',
                         fdp = 'FDP', gruene = "Bündnis 90/Die Grünen",
                         linke_pds = 'Die Linke/PDS', piraten = 'Piraten',
                         sonstige = 'Sonstige', spd = 'SPD')) %>%
  filter(!is.na(date)) %>%
  spread(partei, stimmanteil) %>% ungroup() %>%
  select(date, `CDU/CSU`, SPD, `Die Linke/PDS`, AfD, starts_with('B'),
         FDP) %>%
  arrange(desc(date))

write.csv(monatsschnitt, 'daten/schnitt1_monat.csv', row.names = F)

# Wöchentlicher Durchschnitt

wochenschnitt <- df %>% filter(!is.na(jahr), !is.na(woche)) %>%
  group_by(jahr, woche, partei) %>%
  summarise(stimmanteil = round(mean(stimmanteil, na.rm = T), 1)) %>%
  filter(!is.na(stimmanteil)) %>%
  mutate(date = as.Date(paste(jahr, woche, 1, sep="-"), "%Y-%U-%u"),
         partei = dplyr::recode(partei, afd = 'AfD', cdu_csu = 'CDU/CSU',
                         fdp = 'FDP', gruene = "Bündnis 90/Die Grünen",
                         linke_pds = 'Die Linke/PDS', piraten = 'Piraten',
                         sonstige = 'Sonstige', spd = 'SPD')) %>%
  filter(!is.na(date)) %>%
  spread(partei, stimmanteil) %>% ungroup() %>%
  select(date, `CDU/CSU`, SPD, `Die Linke/PDS`, AfD, starts_with('B'),
         FDP) %>%
  arrange(date)

write.csv(wochenschnitt, 'daten/schnitt1.csv', row.names = F)
