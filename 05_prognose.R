# Signal&Rauschen
# 2017-06-22
# merge data

# rm(list = ls())
# setwd('~/Dropbox/Signal&Rauschen/12_Prognose')
# setwd('~/Git/signalundrauschen')

library(tidyr)
library(foreign)
library(dplyr)
library(lubridate)

# S&R Schnitt ------------------------------------------------------------------

s <- read.csv('daten/schnitt2.csv', stringsAsFactors = F) %>% tbl_df()
s$date <- ymd(s$date)

names(s) <- c('date', 'cdu_csu', 'spd', 'linke_pds', 'afd', 'gruene', 'fdp')

s <-
s %>% gather(party, stimmanteil, -date)

# weights ---------------------------------------------------------------------

w <- read.csv('input/weights.csv', stringsAsFactors = F) %>% tbl_df()
w$date <- ymd(w$date)

# combine ----------------------------------------------------------------------

df <- left_join(s, w, by = c('party', 'date'))

df <-
df %>% mutate(prognose = weight_s / (weight_s + weight_f) * voteshare_hat +
                weight_f / (weight_s + weight_f) * stimmanteil)

df <- df %>% filter(!is.na(prognose))

df <-
  df %>% select(date, party, prognose) %>%
  mutate(party = dplyr::recode(party, afd = 'AfD', cdu_csu = 'CDU/CSU',
                               fdp = 'FDP', gruene = "Bündnis 90/Die Grünen",
                               linke_pds = 'Die Linke/PDS', piraten = 'Piraten',
                               sonstige = 'Sonstige', spd = 'SPD')) %>%
  tidyr::spread(party, prognose) %>%
  ungroup() %>%
  select(date, `CDU/CSU`, SPD, `Die Linke/PDS`, AfD, starts_with('B'),
         FDP)

write.csv(df, 'daten/schnitt3.csv', row.names = F)

# ggplot(dfig, aes(x = date, y = prognose, color = party)) + geom_line() +
#   geom_hline(yintercept = 5, linetype = 'dashed', alpha = .9) +
#   scale_color_manual(values = c('darkblue', 'black', 'gold1', 'darkgreen',
#                                 'purple', 'darkred')) +
#   theme_bw()
#
# dfig2 <- dfig %>% filter(date == ymd('2017-06-29'))
# dfig2 <- bind_rows(dfig2, dfig2)
# dfig2$date[7:12] <- ymd('2017-09-24')
#
# png('prognose.png')
# ggplot(dfig, aes(x = date, y = prognose, color = party)) + geom_line() +
#   geom_line(data = dfig2, linetype = 'dashed') +
#   geom_hline(yintercept = 5, linetype = 'dashed', alpha = .9) +
#   scale_color_manual(values = c('darkblue', 'black', 'gold1', 'darkgreen',
#                                 'purple', 'darkred')) +
#   theme_bw()
# dev.off()
