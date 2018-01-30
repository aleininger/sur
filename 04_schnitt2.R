# 02 schnitt2.R: Berechnet die Durchschnitte

# setwd('~/Dropbox/Signal&Rauschen/06_Daten & Visualisierung/')  # Arndt Pfad
# setwd('~/Git/signalundrauschen')

library(dplyr)
library(lubridate)
library(tidyr)

df <- read.csv('daten/umfragedaten.csv', stringsAsFactors = F) %>% tbl_df()
df$datum <- ymd(df$datum)


# Zeitraum ---------------------------------------------------------------------

# tmp <- data_frame(t = -14:0, y = 1 / (1+exp(-t-7)))
# f <-
# ggplot(tmp, aes(x = t, y = y)) + geom_line() + scale_x_continuous(breaks = -14:0)
#
# ggsave('f_zeitgewichtung.png', f)

# Samplegröße ------------------------------------------------------------------

# t-Wert
df$t <- qt(.975, df$befragte - 1)

df$tgewicht <- 1 / df$t

# tmp <- data_frame(n = 50:3000, t = qt(.975, n))
#
# q <- as.numeric(quantile(df$befragte, na.rm = T))
#
# f <-
# ggplot(tmp, aes(x = n, y = t)) + geom_line() +
#   scale_x_continuous(breaks = q) + scale_y_continuous(breaks = seq(1.9,2,.01))
#
# ggsave('f_tgewichtung.png', f)

# Prognosefehler ---------------------------------------------------------------

fehler <- read.csv('input/fehler.csv', stringsAsFactors = F)

# RNSE an Datensatz mergen
df <- left_join(df, fehler, by = c('institut', 'partei'))

df$rmsegewicht <- 1 / df$rmse

# Gewichteter Mittelwert -------------------------------------------------------

# Neuer (leerer) Datensatz: jeder Tag des Jahres bis momentanes Datum und alle parteien, stimmanteile

daten <- seq(ymd('2017-01-01'), Sys.Date(), by = 'days')

# Loop durch den neuen Datensatz
# darin Reduzierung des alten auf die zwei Woche vor Tag

for(i in 1:length(daten)) {
  #  print(i)
  tmp <- df %>% filter(datum <= daten[i], datum >= daten[i] - weeks(2))
  # Anlegen der Zeitgewichte
  tmp$zeitabstand <- tmp$datum - daten[i]
  tmp$zeitgewicht <- 1 / (1 + exp(-as.integer(tmp$zeitabstand) - 7))
  # Zusammenfassen der Gewichte
  tmp$gewicht <- tmp$zeitgewicht + tmp$tgewicht + tmp$rmsegewicht


  # tmp %>% select(zeitabstand, zeitgewicht, t, tgewicht, rmse, rmsegewicht, gewicht)

  # Aggregation
  tmp <- tmp %>% filter(!is.na(tmp$gewicht)) %>% group_by(partei) %>%
    summarise(stimmanteil = round(weighted.mean(stimmanteil, gewicht,
                                                na.rm = T), 1))
  tmp$datum <- daten[i]

  if(i == 1) {
    schnitte <- tmp
  } else {
    schnitte <- bind_rows(schnitte, tmp)
  }

}

# f <-
# ggplot(schnitte, aes(x = datum, y = stimmanteil, color = partei)) +
#   geom_line()
#
# ggsave('f_schnitt2.png', f)

schnitte <- schnitte %>%
  mutate(partei =
           dplyr::recode(partei, afd = 'AfD', cdu_csu = 'CDU/CSU',
                         fdp = 'FDP', gruene = "Bündnis 90/Die Grünen",
                         linke_pds = 'Die Linke/PDS', piraten = 'Piraten',
                         sonstige = 'Sonstige', spd = 'SPD')) %>%
         rename(date = datum) %>%
  tidyr::spread(partei, stimmanteil) %>%
  ungroup() %>%
  select(date, `CDU/CSU`, SPD, `Die Linke/PDS`, AfD, starts_with('B'),
         FDP)

write.csv(schnitte, 'daten/schnitt2.csv', row.names = F)
