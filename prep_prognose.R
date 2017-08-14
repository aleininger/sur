# prep_prognose.R: Stellt Daten für Prognose bereit

# setwd('~/Dropbox/Signal&Rauschen/06_Daten & Visualisierung/')  # Arndt Pfad
# setwd('~/Git/signalundrauschen')

library(foreign)
library(dplyr)
library(lubridate)
library(tidyr)

# rm(list= ls())

# ------------------------------------------------------------------------------
# Prognosemodell (Forecast)
# ------------------------------------------------------------------------------

# data
d <- read.dta('input/master_nation_forecast.dta') %>% tbl_df()

# forecast

f <-
  d %>% filter(state == 'Bundesgebiet', elec_year == 2017) %>%
  select(party, elec_year, state, voteshare_hat)

# errors (without AfD)

tmp <-
  d %>% filter(state == 'Bundesgebiet', elec_year >= 1998, elec_year < 2017) %>%
  select(party, elec_year, state, voteshare_hat, voteshare) %>%
  mutate(error = voteshare_hat - voteshare,
         error2 = error^2) %>%
  group_by(party) %>% summarise(weight_f = mean(error2))
# print(n = nrow(.))

# %>%
#   group_by(party) %>% summarise(weight_f = sum(error^2) / n())

# errors (AfD)

tmp$weight_f[which(tmp$party == 'afd')] <-
  d %>% filter(state != 'Bundesgebiet', party == 'afd', elec_year == 2013)  %>%
  summarise(sum(error^2) / n()) %>% as.numeric()

f <- left_join(f, tmp, by = 'party')

# ------------------------------------------------------------------------------
# S & R Schnitt für vergangene Wahlen
# ------------------------------------------------------------------------------

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

df$tgewicht[which(is.na(df$tgewicht))] <- 1 / qt(.975, 800)

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

# Datensatz auf relevanten Zeitraum reduzieren
elec_dates <- read.csv('input/wahldaten.csv', stringsAsFactors = F)
elec_dates <- ymd(elec_dates$datum[14:18])

sub <-
df %>% mutate(vdatum = ymd(vdatum)) %>% arrange(vdatum) %>%
  filter((vdatum < elec_dates[1] & vdatum > elec_dates[1] - weeks(2)) |  # 14
         (vdatum < elec_dates[2] & vdatum > elec_dates[2] - weeks(2)) |  # 15
         (vdatum < elec_dates[3] & vdatum > elec_dates[3] - weeks(2)) |  # 16
         (vdatum < elec_dates[4] & vdatum > elec_dates[4] - weeks(2)) |  # 17
         (vdatum < elec_dates[5] & vdatum > elec_dates[5] - weeks(2))  # 18
         )

# Tatsächliche Wahlergebnisse ergänzen

elec <- read.csv('input/view_election.csv', stringsAsFactors = F) %>% tbl_df()

elec_results <-
elec %>% mutate(vdatum = ymd(election_date), jahr = year(vdatum)) %>%
  filter(country_name == 'Germany', election_type == 'parliament',
                vdatum > ymd('1998-01-01'),
                party_name_short %in% c('SPD', 'CDU', 'B90/Gru',
                                        'CSU', 'FDP', 'Li/PDS',
                                        'AfD')) %>%
  select(jahr, party_name_short, vote_share) %>%
  tidyr::spread(party_name_short, vote_share) %>%
  mutate(`CDU/CSU` = CDU + CSU) %>% select(-CDU, -CSU) %>%
  tidyr::gather(partei, ergebnis, -jahr) %>%
  mutate(partei = recode(partei, `CDU/CSU` = 'cdu_csu', SPD = 'spd',
                         `B90/Gru` = 'gruene', FDP = 'fdp',
                         `Li/PDS` = 'linke_pds',
                         AfD = 'afd'))

sub <- left_join(sub, elec_results, by = c('jahr', 'partei'))

# Einfache Abweichung berechnen

sub$prognosefehler <- abs(sub$stimmanteil - sub$ergebnis)
sub$prognosefehler2 <- (sub$stimmanteil - sub$ergebnis)^2

# sub%>% filter(jahr == 1998) %>% select(vdatum, institut, partei, stimmanteil,
#                                        ergebnis, prognosefehler, prognosefehler2)

# RMSE (pro Institut-Partei berechnen), über alle Wahlen hinweg
fehler <-
sub %>% group_by(institut, partei) %>%
  summarise(mae = mean(prognosefehler, na.rm = T),
            rmse = sqrt(mean(prognosefehler2, na.rm = T)))

# RNSE an Datensatz mergen
df <- left_join(df, fehler, by = c('institut', 'partei'))

df$rmsegewicht <- 1 / df$rmse

# Gewichteter Mittelwert -------------------------------------------------------

# Neuer (leerer) Datensatz: jeder Tag des Jahres bis momentanes Datum und alle parteien, stimmanteile

daten <- c(seq(elec_dates[1]-days(132), elec_dates[1], by = 'days'),  # 1998
           seq(elec_dates[2]-days(132), elec_dates[2], by = 'days'),  # 2002
           seq(elec_dates[3]-days(132), elec_dates[3], by = 'days'),  # 2005
           seq(elec_dates[4]-days(132), elec_dates[4], by = 'days'),  # 2009
           seq(elec_dates[5]-days(132), elec_dates[5], by = 'days'))  # 2013

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
schnittebackup <- schnitte

# Die S&R Schnitte für die vergangenen fünf Wahlen
# schnitte <- schnittebackup

schnitte <-
schnitte %>% mutate(jahr = year(datum)) %>%
  filter(!(partei == 'afd' & jahr < 2013))

# Tatsächliche Wahlergebnisse ranmergen
elecdates <- data_frame(jahr = year(elec_dates), elec_date = elec_dates)

elecresults <- left_join(elec_results, elecdates, by = c('jahr'))

schnitte <- left_join(schnitte, elecresults, by = c('jahr', 'partei'))

# Abstand zur Wahl
schnitte$abstand <- schnitte$elec_date - schnitte$datum

# Fehler berechnen
schnitte$error <- schnitte$stimmanteil - schnitte$ergebnis
schnitte$error2 <- schnitte$error^2



# Fehler zusammenfassen
schnitte <-
schnitte %>% group_by(abstand, partei) %>%
  summarise(meanerror2 = mean(error2, na.rm = T))

# ggplot(schnitte, aes(x = abstand, y = meanerror2, color = partei)) + geom_line()
# write.csv(schnitte, 'input/schnitt2_1998-2013.csv', row.names = F)

# ------------------------------------------------------------------------------
# Combine the two into one dataset of weights
# ------------------------------------------------------------------------------

f <-
  f %>% select(party, voteshare_hat, weight_f) %>% mutate(party = recode(party, die_linke_pds = 'linke_pds'))

s <-
  schnitte %>% rename(party = partei, weight_s = meanerror2)

# merge the two

w <- left_join(s, f, by = 'party')

w <-
w %>% mutate(weight_umfrage = weight_f / (weight_s + weight_f),
             weight_forecast = weight_s / (weight_s + weight_f),
             weight_gesamt = weight_umfrage + weight_forecast)

w$date <- ymd('2017-09-24') - w$abstand

w$date <- ymd(w$date)

w$party <- ordered(w$party, levels = c('cdu_csu', 'spd', 'linke_pds',
                                       'gruene', 'fdp', 'afd'))
w$Party <- recode(w$party, afd = 'AfD',
                  cdu_csu = 'CDU/CSU',
                  fdp = 'FDP',
                  gruene = 'Bündnis 90/Die Grünen',
                  linke_pds = 'Die Linke/PDS',
                  spd = 'SPD')

png('gew_umfragen.png', width = 600, height = 300)
ggplot(w, aes(x = date, y = (weight_f / (weight_s + weight_f)), color = Party)) +
  geom_line(size = 1) +
  xlab('2017') + ylab('Gewichtung der Umfrage') +
  scale_color_manual(values = c('black', 'darkred', 'purple', 'darkgreen',
                                'gold1', 'darkblue'), name = '') +
  theme_bw() + theme(legend.position = 'bottom') +
  guides(colour = guide_legend(nrow = 1))
  # ggtitle('Gewicht Umfragen')
dev.off()

png('gew_forecast.png', width = 600, height = 300)
ggplot(w, aes(x = date, y = weight_s / (weight_s + weight_f), color = Party)) + geom_line(size = 1) +
  xlab('2017') + ylab('Gewichtung der Prognose') +
  scale_color_manual(values = c('black', 'darkred', 'purple', 'darkgreen',
                                'gold1', 'darkblue'), name = '') +
  theme_bw() + theme(legend.position = 'bottom') +
  guides(colour = guide_legend(nrow = 1))
  # ggtitle('Gewicht Forecast')
dev.off()

write.csv(w, 'input/weights.csv', row.names = F)