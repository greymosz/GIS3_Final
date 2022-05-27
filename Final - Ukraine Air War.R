# Ukraine data attempt

# Setup:
setwd("~/Documents/University of Chicago/Fourth Year/GIS III/Final")
library(sf)
library(tmap)
library(tidyverse)

### CREATE INCIDENT DATASET


## Read in data:
download.file(url = "https://github.com/zhukovyuri/VIINA/raw/master/Data/events_latest.csv", 
                         destfile = "latest_events.csv")
ukraine <- read.csv(file = "latest_events.csv") # https://github.com/zhukovyuri/VIINA Documentation is here.


## Spatialize data:
ukraine_sf <- st_as_sf(ukraine, coords = c('longitude', 'latitude'), crs = st_crs(4326)) # Convert to SF object


## Clean data (remove irrelevant columns):
ukraine_clean <- subset(ukraine_sf, select = c('event_id', 'date', 'a_rus_b',
                                               'a_ukr_b', 'a_civ_b', 'a_other_b', 't_aad_b',
                                               't_airstrike_b', 't_armor_b', 't_artillery_b',
                                               't_control_b', 't_occupy_b', 't_hospital_b', 
                                               't_milcas_b', 't_civcas_b', 'geometry')) #Select relevant column


## Write to geojson:
write_sf(obj = ukraine_clean, dsn = "ukraine_clean.geojson")


### CREATE OBLAST-LEVEL LINGUISTIC DATASET


## Read in oblast boundaries:
download.file(url = 'https://stacks.stanford.edu/file/druid:gg870xt4706/data.zip', 
              destfile = 'oblast_boundary.zip')
unzip(zipfile = 'oblast_boundary.zip')
oblast_boundary <- read_sf(dsn = 'UKR_adm1.shp', crs = st_crs(4326)) # Create oblast-level boundaries


## Clean boundary data (remove unnecessary columns):
oblast_clean <- subset(oblast_boundary, select = c('ID_1', 'NAME_1', 'TYPE_1', 'geometry'))


## Read in linguistic data:
u = 'https://data.humdata.org/dataset/f966a108-4bfe-4ec6-b4c2-42526d99e076/resource/55a058ef-a719-4fe0-913d-46f2ee673ed3/download/ua_lang_admin1_v02.csv'
oblast_lan <- read.csv(url(u))


## Clean linguistic data (remove unnecessary columns):
oblast_lan <- oblast_lan %>% slice(-1, )
lan_clean <- oblast_lan %>% subset(select = c('admin1_name', 'admin1_pcode', 'number_of_named_languages',
                                              'main_language', 'main_language_share', 'main_first_language',
                                              'main_first_language_share', 'main_second_language', 
                                              'main_second_language_share', 'Ukrainian', 'Russian',
                                              'pop_total', 'pop_male', 'pop_female'))


## Prepare linguistic dataset for merge with sf polygon boundaries by adding a column 
## that alphabetizes in the same manner as the boundaries dataset: 
lan_clean$name <- c('Crimea', 'Vinnytska', 'Volynska', 'Dnipropetrovska', 'Donetska', 'Zhytomyrska', 
                    'Transcarpathia', 'Zaporizka', 'Ivano-Frankivska', 'Kievska', 'Kirovohradska', 
                    'Luhanska', "L'vivska", 'Mykolaivska', 'Odeska', 'Poltavska', 'Rivnenska', 'Sumska', 
                    'Ternopilska', 'Kharkivska', 'Khersonska', 'Khmelnytska', 'Cherkaska', 'Chernivetska',
                    'Chernihivska', 'Kiev city', 'Sevastopol') # Add name list to alphabetize data


## Alphabetize linguistic dataset:
lan_clean <- lan_clean[order(lan_clean$name), ] 


## Add an ID_1 column, matching the ID_1 column in the oblast boundary dataset, to use as a key for merging:
lan_clean$ID_1 <- c(1:27) # Add in key ID_1 column by which to join lan_clean to oblast_clean


## Join linguistic data to boundary data:
languages <- left_join(lan_clean, oblast_clean)


## Clean and spatialize resulting data:
languages <- languages %>% subset(select = -c(name, NAME_1, ID_1, admin1_pcode)) 
languages <- st_as_sf(languages, crs = st_crs(4326))

## Write to geojson for kepler.gl compatibility:
st_write(languages, dsn = "languages.geojson")


### We now have two dataframes: one of war-related events from VIINA and one 
### spatially enabled linguistic dataset.


### CREATE METRIC OF EFFECTIVE AIR DEFENSE (EAD):


## Subset Ukrainian anti-aircraft events:
aa <- ukraine_clean %>% filter(a_ukr_b == 1, t_aad_b == 1) 


## Write to geojson for kepler.gl compatibility:
st_write(obj = aa, dsn = "aa.geojson")


## Subset Russian airstrikes:
strikes <- ukraine_clean %>% filter(a_rus_b == 1, t_airstrike_b == 1)


## Write to geojson for kepler.gl compatibility:
st_write(obj = strikes, dsn = "strikes.geojson")


## Count number of aa events per oblast and add counts to oblast-level linguistic dataset:
aa <- read_sf("aa.geojson")
oblast <- read_sf("languages.geojson")
#sf_use_s2(FALSE)
count <- st_intersection(oblast, aa)
aa_count <- table(count$admin1_name) %>% data.frame()
master_oblast <- merge(oblast, aa_count, by.x = "admin1_name", by.y = "Var1", all.x = TRUE)


## Clean master oblast-level file: remove NAs and rename column.
master_oblast[is.na(master_oblast)] = 0
master_oblast <- master_oblast %>% rename(aa_events = Freq)


# Count number of airstrikes per oblast and add counts to oblast-level linguistic dataset:
strikes <- read_sf("strikes.geojson")
count <- st_intersection(oblast, strikes)
strikes_count <- table(count$admin1_name) %>% data.frame()
master_oblast <- merge(master_oblast, strikes_count, by.x = "admin1_name", by.y = "Var1", all.x = TRUE)


## Clean master oblast-level file: remove NAs and rename column.
master_oblast[is.na(master_oblast)] = 0
master_oblast <- master_oblast %>% rename(strike_events = Freq)


## Construct metric of Effective Air Defence (EAD):
master_oblast$ead <- master_oblast$aa_events/master_oblast$strike_events


## Write to geojson for kepler.gl compatibiility:
st_write(obj = master_oblast, dsn = "master_oblast.geojson") 


## Construct CSVs of aa and strikes for kepler.gl hexbinning compatibility:
aa_csv <- ukraine %>% filter(a_ukr_b == 1, t_aad_b == 1) 
st_write(obj = aa_csv, dsn = "aa.csv")
strikes_csv <- ukraine %>% filter(a_rus_b == 1, t_airstrike_b == 1)
st_write(obj = strikes_csv, dsn = "strikes.csv")


## Read in and select 10 largest Ukrainian cities:

cities <- read.csv("ukraine_cities.csv")
largest_cities <- cities[1:10, ]
View(largest_cities)
write_csv(largest_cities, "largest_cities.csv")


