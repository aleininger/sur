# 02 schnitt1.R: Berechnet die Durchschnitte

# setwd('~/Dropbox/Signal&Rauschen/06_Daten & Visualisierung/')  # Arndt Pfad
# setwd('~/Git/signalundrauschen')

library(dplyr)
library(lubridate)
library(tidyr)

df <- read.csv('umfragedaten.csv', stringsAsFactors = F) %>% tbl_df()

df$monat <- month(df$datum) # Monat der Umfrage

df$woche <- week(df$datum) # Woche der Umfrage

# Monatlicher Durchschnitt

monatsschnitt <-
  df %>% filter(!is.na(jahr), !is.na(monat)) %>%
  group_by(jahr, monat, partei) %>%
  summarise(stimmanteil = mean(stimmanteil, na.rm = T)) %>%
  filter(!is.na(stimmanteil)) %>%
  mutate(date = paste(jahr, monat, '01', sep = '-'),
         partei = recode(partei, afd = 'AfD', cdu_csu = 'CDU/CSU',
                         fdp = 'FDP', gruene = "Bündnis 90/Die Grünen",
                         linke_pds = 'Die Linke/PDS', piraten = 'Piraten',
                         sonstige = 'Sonstige', spd = 'SPD')) %>%
  spread(partei, stimmanteil) %>% ungroup() %>%
  select(date, `CDU/CSU`, SPD, `Die Linke/PDS`, AfD, `Bündnis 90/Die Grünen`,
         FDP)

write.csv(monatsschnitt, 'schnitt1_monat.csv', row.names = F)

# Wöchentlicher Durchschnitt

wochenschnitt <- df %>% filter(!is.na(jahr), !is.na(woche)) %>%
  group_by(jahr, woche, partei) %>%
  summarise(stimmanteil = mean(stimmanteil, na.rm = T)) %>%
  filter(!is.na(stimmanteil)) %>%
  mutate(date = as.Date(paste(jahr, woche, 1, sep="-"), "%Y-%U-%u"),
         partei = recode(partei, afd = 'AfD', cdu_csu = 'CDU/CSU',
                         fdp = 'FDP', gruene = "Bündnis 90/Die Grünen",
                         linke_pds = 'Die Linke/PDS', piraten = 'Piraten',
                         sonstige = 'Sonstige', spd = 'SPD')) %>%
  spread(partei, stimmanteil) %>% ungroup() %>%
  select(date, `CDU/CSU`, SPD, `Die Linke/PDS`, AfD, `Bündnis 90/Die Grünen`,
         FDP)

write.csv(wochenschnitt, 'schnitt1_woche.csv', row.names = F)