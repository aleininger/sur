# 00 scrape.R: installs packages necessary for scrape.R
packages <- c('htmltab', 'string', 'dplyr', 'lubridate', 'tidyr')
for (p in packages) {
  if (p %in% installed.packages()[,1]) {
    print(paste0(p, ' is installed. Will now load ', p,'.'))
    require(p, character.only=T)
  }
  else {
    print(paste0(p, ' is NOT installed. Will now install ', p,'.'))
    install.packages(p)
    require(p, character.only=T)
  }
}
rm(packages, p)