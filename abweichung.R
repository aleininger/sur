# setwd('~/Seafile/UMZ/nebentaetigkeit/signalundrauschen')
#
# library(dplyr)
# library(lubridate)
#
# df <- read.csv('umfragedaten.csv', stringsAsFactors = F)
#
# df$datum <- as.Date(df$datum)
#
# df <- df%>% arrange(desc(datum))
#

df$abweichung <- as.numeric(NA)

for(i in 1:nrow(subset(df, jahr == 2017))) {
  tmp <- subset(df, jahr == 2017) %>% filter(datum < df$datum[i], datum > df$datum[i] - months(6))
  
  # Durchschnitt der anderen Institute
  andere <- tmp %>% filter(institut != df$institut[i], partei == df$partei[i]) %>%
    summarise(stimmanteil = mean(stimmanteil, na.rm = T)) %>% as.numeric
  
  # Durchschnitt dieses Instituts
  institut <- tmp %>% filter(institut == df$institut[i], partei == df$partei[i]) %>%
    summarise(stimmanteil = mean(stimmanteil, na.rm = T)) %>% as.numeric
  
  df$abweichung[i] <- round(institut - andere, 1)
}
