# setwd('~/Git/signalundrauschen/')

library(dplyr)
library(lubridate)
library(tidyr)

df <- read.csv('daten/umfragedaten.csv', stringsAsFactors = F) %>% tbl_df()
df$datum <- ymd(df$datum)

# Datensatz auf relevanten Zeitraum reduzieren
elec_dates <- read.csv('input/wahldaten.csv', stringsAsFactors = F)
elec_dates <- ymd(elec_dates$datum[14:19])

sub <-
  df %>% mutate(vdatum = ymd(vdatum)) %>% arrange(vdatum) %>%
  filter((vdatum < elec_dates[1] & vdatum > elec_dates[1] - weeks(2)) |  # 14
           (vdatum < elec_dates[2] & vdatum > elec_dates[2] - weeks(2)) |  # 15
           (vdatum < elec_dates[3] & vdatum > elec_dates[3] - weeks(2)) |  # 16
           (vdatum < elec_dates[4] & vdatum > elec_dates[4] - weeks(2)) |  # 17
           (vdatum < elec_dates[5] & vdatum > elec_dates[5] - weeks(2) |  # 18
           (vdatum < elec_dates[6] & vdatum > elec_dates[6] - weeks(2)))  # 19
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

btw2017 <- read.csv('input/btw2017.csv', stringsAsFactors = F) %>% tbl_df()

btw2017 <-
btw2017 %>% rename(partei = partygroup,
                   ergebnis = voteshare) %>%
  filter(partei != 'Sonstige') %>%
  mutate(jahr = 2017,
         partei = recode(partei, AfD = 'afd',
                         `Bündnis 90/Die Grünen` = 'gruene',
                         `CDU/CSU` = 'cdu_csu',
                         `Die Linke` = 'die_linke',
                         FDP = 'fdp',
                         SPD = 'spd')) %>%
  select(jahr, partei, ergebnis)

elec_results <- bind_rows(elec_results, btw2017) %>%
  distinct(jahr, partei, .keep_all = T) %>%
  arrange(partei, desc(jahr))

sub <- left_join(sub, elec_results, by = c('jahr', 'partei'))

# Einfache Abweichung berechnen

sub$prognosefehler <- abs(sub$stimmanteil - sub$ergebnis)
sub$prognosefehler2 <- (sub$stimmanteil - sub$ergebnis)^2

sub%>% filter(jahr == 2017) %>%
  select(vdatum, institut, partei, stimmanteil, ergebnis, prognosefehler,
                                       prognosefehler2)

# RMSE (pro Institut-Partei berechnen), über alle Wahlen hinweg
fehler <-
  sub %>% group_by(institut, partei) %>%
  summarise(mae = mean(prognosefehler, na.rm = T),
            rmse = sqrt(mean(prognosefehler2, na.rm = T)))

# Speichern
write.csv(fehler, 'input/fehler.csv', row.names = F)