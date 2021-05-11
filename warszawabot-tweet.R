# Losowanie punktu i twit warszawabot

library(rtweet)
library(tidyverse)
library(lubridate)
library(distill)
library(rmarkdown)

# Twitter token 
warszawabot_token <- rtweet::create_token(
  app = "warszawabot",
  consumer_key =    Sys.getenv("TWITTER_CONSUMER_API_KEY"),
  consumer_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"),
  access_token =    Sys.getenv("TWITTER_ACCESS_TOKEN"),
  access_secret =   Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET"),
  set_renv = FALSE
)

# tylko do testów
# warszawabot_token <- readRDS("~/.rtweet_token_warszawabot.rds")

# Współrzędne punktu w Warszawie .

# centrum 52.188268, 20.885447 - 52.272606, 21.141751
lon <- round(runif(1, 20.885, 21.141), 3)
lat <- round(runif(1, 52.188, 52.272), 3)


# po 600x400 dodany był @2x
img_url <- paste0(
  "https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/",
  paste0("pin-l-marker+015(",lon,",",lat,")/", lon, ",", lat),
  ",15,0/850x500?access_token=",
  Sys.getenv("MAPBOX_PUBLIC_ACCESS_TOKEN")
)

# Pobranie zdjęcia satelitarnego z MapBox

temp_file <- tempfile()
download.file(img_url, temp_file)

# Współrzędne punktu i adres do mapy w OpenStreetMaps

latlon_details <- paste0("Jestem botem, który co 1 h wybiera losowo punkt w #Warszawa, pobiera zdjęcie satelitarne. Poniżej pkt o współ.: ", lat, ", ", lon, " \n", "Nie poznajesz? Zobacz na mapie. ",
                         "https://www.openstreetmap.org/#map=17/", lat, "/", lon, "/"
)

# Wysłanie twita ze zdjęciem satelitarnym
rtweet::post_tweet(
  status = latlon_details,
  media = temp_file,
  token = warszawabot_token
)

# pobranie ostatnich twitow (max 100)
df <- get_timeline(user = "warszawabot", n=500, token = botkrakow_token)

df_dzisiejsze <- df %>% 
  unnest(ext_media_url) %>% 
  # filter(created_at >= ymd(Sys.Date(), tz="Europe/Warsaw")) %>%
  select(user_id, status_id, created_at, text, favorite_count, retweet_count, followers_count, statuses_count, 
         ext_media_url) %>% 
  mutate_all(as.character)


# pobranie aktualnego loga

log_data <- read_csv("./data/warszawabot_archiwum_twitow.csv", 
                     col_types = cols(user_id = col_character(), 
                                      status_id = col_character(), created_at = col_character(),
                                      favorite_count = col_character(), retweet_count = col_character(),
                                      followers_count = col_character(), statuses_count = col_character(),
                                      ext_media_url = col_character()))

# wybieram wiersze do archiwzacji

log_new_data <- anti_join(df_dzisiejsze, log_data, by = "status_id")

# dodanie do istniejącego loga na dysku nowych twitow

write_csv(log_new_data,"./data/warszawabot_archiwum_twitow.csv",append = TRUE)
# write_csv(df_dzisiejsze,"./data/archiwum_twitow.csv")

# Generowanie mapy aktualnych punktów (dawne mapa_punktów_botkrakow.RMD)

rmarkdown::render("mapa_punktow_warszawabot.Rmd", output_file = "./_site/mapa_punktow_warszawabot.html")
