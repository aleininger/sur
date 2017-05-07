# 01 scrape.R (alternativ): zieht die Daten von wahlrecht.de

# setwd('~/Dropbox/Signal&Rauschen/06_Daten & Visualisierung/')  # Arndt Pfad

library(htmltab)
library(dplyr)
library(stringr)
library(lubridate)

# Wenn das Script zum Erstenmal ausgeführt wird, dann werden alle Daten gezogen, ansonsten nur die aktuellen. Anschließend werden die alten und die neuen Daten zusammengefügt und Duplikate gelöscht.
if (!file.exists('scraped_tables.RData')) {
  cat("First Time. Fetch all files.")
  urls <- c(
    # Allensbach
    'http://www.wahlrecht.de/umfragen/allensbach.htm',
    'http://www.wahlrecht.de/umfragen/allensbach/2013.htm',
    'http://www.wahlrecht.de/umfragen/allensbach/2009.htm',
    'http://www.wahlrecht.de/umfragen/allensbach/2005.htm',
    'http://www.wahlrecht.de/umfragen/allensbach/2002.htm',
    # Emnid
    'http://www.wahlrecht.de/umfragen/emnid.htm',
    'http://www.wahlrecht.de/umfragen/emnid/2013.htm',
    paste0('http://www.wahlrecht.de/umfragen/emnid/', 1998:2008, '.htm'),
    # Forsa
    'http://www.wahlrecht.de/umfragen/forsa.htm',
    'http://www.wahlrecht.de/umfragen/forsa/2013.htm',
    paste0('http://www.wahlrecht.de/umfragen/forsa/',1998:2008,'.htm'),
    # Forschungsgruppe Wahlen
    # Projektion
    'http://www.wahlrecht.de/umfragen/politbarometer.htm',
    'http://www.wahlrecht.de/umfragen/politbarometer/politbarometer-2013.htm',
    'http://www.wahlrecht.de/umfragen/politbarometer/politbarometer-2009.htm',
    'http://www.wahlrecht.de/umfragen/politbarometer/politbarometer-2005.htm',
    'http://www.wahlrecht.de/umfragen/politbarometer/politbarometer-2002.htm',
    'http://www.wahlrecht.de/umfragen/politbarometer/politbarometer-1998.htm',
    # Politische Stimmung
    'http://www.wahlrecht.de/umfragen/politbarometer/stimmung.htm',
    'http://www.wahlrecht.de/umfragen/politbarometer/stimmung-2013.htm',
    'http://www.wahlrecht.de/umfragen/politbarometer/stimmung-2009.htm',
    'http://www.wahlrecht.de/umfragen/politbarometer/stimmung-2005.htm',
    'http://www.wahlrecht.de/umfragen/politbarometer/stimmung-2002.htm',
    'http://www.wahlrecht.de/umfragen/politbarometer/stimmung-1998.htm',
    # GMS
    # Projektion
    'http://www.wahlrecht.de/umfragen/gms.htm',
    'http://www.wahlrecht.de/umfragen/gms/projektion-2009.htm',
    'http://www.wahlrecht.de/umfragen/gms/projektion-2005.htm',
    # Politische Stimmung
    'http://www.wahlrecht.de/umfragen/gms/stimmung.htm',
    'http://www.wahlrecht.de/umfragen/gms/stimmung-2009.htm',
    'http://www.wahlrecht.de/umfragen/gms/stimmung-2005.htm',
    # Infratest dimap
    'http://www.wahlrecht.de/umfragen/dimap.htm',
    'http://www.wahlrecht.de/umfragen/dimap/2013.htm',
    paste0('http://www.wahlrecht.de/umfragen/dimap/', 1998:2008, '.htm'),
    # INSA
    'http://www.wahlrecht.de/umfragen/insa.htm'
  )

  # Tabellen herunterladen und aneinanderhängen
  d <- data.frame()
  for(url in urls) {
    cat(url)
    tmp <- htmltab(url, which = 2)
    names(tmp)[1] <- 'datum'
    tmp$institut <-
      str_extract(url,'(allensbach|emnid|forsa|politbarometer|gms|dimap|insa)')
    tmp$url <- url
    d <- bind_rows(d, tmp)
  }
  # Duplikate entfernen
  d <- d %>% distinct(.keep_all = TRUE)

} else {
  cat("Fetch only updated files.")
  urls <- c(
    # Allensbach
    'http://www.wahlrecht.de/umfragen/allensbach.htm',
    # Emnid
    'http://www.wahlrecht.de/umfragen/emnid.htm',
    # Forsa
    'http://www.wahlrecht.de/umfragen/forsa.htm',
    # Forschungsgruppe Wahlen
    # Projektion
    'http://www.wahlrecht.de/umfragen/politbarometer.htm',
    # Politische Stimmung
    'http://www.wahlrecht.de/umfragen/politbarometer/stimmung.htm',
    # GMS
    # Projektion
    'http://www.wahlrecht.de/umfragen/gms.htm',
    # Politische Stimmung
    'http://www.wahlrecht.de/umfragen/gms/stimmung.htm',
    # Infratest dimap
    'http://www.wahlrecht.de/umfragen/dimap.htm',
    # INSA
    'http://www.wahlrecht.de/umfragen/insa.htm'
  )

  # Tabellen herunterladen und aneinanderhängen
  d_new <- data.frame()
  for(url in urls) {
    cat(url)
    tmp <- htmltab(url, which = 2)
    names(tmp)[1] <- 'datum'
    tmp$institut <-
      str_extract(url,'(allensbach|emnid|forsa|politbarometer|gms|dimap|insa)')
    tmp$url <- url
    d_new <- bind_rows(d_new, tmp)
  }

  # alten Daten laden
  load('scraped_tables.RData')

  # zusammenfügen der alten und neuen Daten
  d <- bind_rows(d_new, d)

  # Duplikate entfernen
  d <- d %>% distinct(.keep_all = TRUE)
}

save(list = 'd', file = 'scraped_tables.RData')


# Formatierung des Ursprungsdatensatzes (1 Zeile = 1 Umfrage)
df <- tbl_df(d)

df <- df %>% select(datum, `CDU/CSU`:PDS)

names(df) <- c('vdatum', 'cdu_csu', 'spd', 'gruene', 'fdp', 'linke', 'afd',
               'sonstige', 'befragte', 'feldzeit', 'institut', 'url',
               'piraten', 'linke_pds', 'empty', 'pds')

df <- df %>% select(-empty)

df <- df %>% filter(!grepl('Wahl', vdatum) & !grepl('wahl', befragte) &
                      !grepl('wahl', feldzeit))  # Wahlergebnisse entfernen

df <- df %>% mutate_at(vars(cdu_csu:sonstige, piraten:pds), str_replace,
                       pattern = ',', replacement = '.') %>%
  mutate_at(vars(cdu_csu:sonstige, piraten:pds), str_replace,
            pattern = ' %', replacement = '') %>%
  mutate_at(vars(cdu_csu:sonstige, piraten:pds), as.numeric)

df$linke_pds[which(is.na(df$linke_pds))] <- df$pds[which(is.na(df$linke_pds))]
df$pds <- NULL
df$linke_pds[which(is.na(df$linke_pds))] <- df$linke[which(is.na(df$linke_pds))]
df$linke <- NULL

df$befragte <-
  str_replace(df$befragte, '≈|>', '') %>%
  str_replace(pattern = '\\.', replacement = '') %>%
  str_replace(pattern = 'O • ', '') %>%
  str_replace(pattern = 'T • ', '')
df$befragte <- as.integer(df$befragte)

# Datumsangaben
df$vdatum_char <- df$vdatum
df$vdatum <- lubridate::dmy(df$vdatum)

df$feldzeit_beginn <- str_extract(df$feldzeit, '\\d\\d\\.\\d\\d\\.')
df$feldzeit_ende <- str_sub(df$feldzeit, -6, -1)

df$datum <-
  ifelse(month(df$vdatum) < as.integer(str_sub(df$feldzeit_ende, -3, -2)),
         paste0(df$feldzeit_ende, year(df$vdatum) - 1),
         paste0(df$feldzeit_ende, year(df$vdatum))
  ) %>% str_extract('\\d\\d\\.\\d\\d\\.\\d\\d\\d\\d') %>% dmy

df$datum_char <- format(df$datum, '%d.%m.%Y')

df$jahr <- year(df$datum)

# Institutsnamen anpassen
df$institut <- car::recode(df$institut, "'allensbach' = 'Allensbach';
                           'emnid' = 'Emnid'; 'forsa' = 'Forsa';
                           'politbarometer' = 'FG Wahlen'; 'gms' = 'GMS';
                           'dimap' = 'Infratest Dimap'; 'insa' = 'INSA'")

# Longfrom (i.e. tidy data): 1 Zeile = 1 Partei in einer Umfrage
df <- df %>% tidyr::gather(key = partei, value = stimmanteil,
                           cdu_csu:sonstige, piraten:linke_pds, -befragte)

df <- df %>% filter(partei != 'sonstige', partei != 'piraten')

# Konfidenzintervalle berechnen
df$se <- sqrt(((df$stimmanteil/100) * (1 - (df$stimmanteil/100))) / df$befragte)  # Standardfehler
df$lwr <- round(df$stimmanteil - 1.96 * df$se * 100, 1)  # Unteres Ende 95% Konfidenzintervall
df$upr <- round(df$stimmanteil + 1.96 * df$se * 100, 1) # Oberes Ende 95% Konfidenzintervall

# Abweichung berechnen ---------------------------------------------------------

df <- df %>% arrange(desc(datum), institut, partei)

source('02_abweichung.R')


write.csv(df, 'umfragedaten.csv', row.names = F)

# pth <- '../07_Daten von Wahlrecht de/'
# write.csv(df, paste0(pth, 'umfragedaten.csv', format(Sys.time(), "%Y-%m-%d_%H-%M")), row.names = F)
