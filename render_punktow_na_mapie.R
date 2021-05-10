# render mapy punktów
library(rmarkdown)
library(distill)
rmarkdown::render("mapa_punktow_botkrakow.Rmd", output_file = "./_site/mapa_punktow_botkrakow.html")
