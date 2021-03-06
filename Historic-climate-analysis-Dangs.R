## Analyzing climate data across Dangs (Data from IIT-Guwahati - Vimal Mishra)

### Steps to follow

#### Step 1. Load the Nil_Ana_Pal shapefile ####


library(raster)
library(sf)
library(rgdal)
library(dplyr)

CI <- st_read("D:\\Forest Owlet Project (Jan 2019- August 2020)\\2020_FO_Resurvey_Analysis\\FO_Resurvey_GIS_Analysis\\Dang_Surveyed_Sites_Data\\Dang_shapefile\\Dang_Shapefile.shp")

## Making sense of the data using ggplot
library(ggplot2)
library(cowplot)
theme_set(theme_cowplot())
(vis <- ggplot(data = CI) +
    geom_sf(fill = "antiquewhite1") +
    coord_sf(xlim = c(73.474,73.949), ylim = c(20.562,21.011)) +
    xlab("Longitude")+ ylab("Latitude")+
    theme(panel.grid.major = element_line(colour = gray(0.25), linetype = "dashed", 
                                          size = 0.25), panel.background = element_rect(fill = "aliceblue"), 
          panel.border = element_rect(fill = NA)))


#### Step 2: Plot the points first and then overlay the grid ####
#### These were coordinates for locations sent to me by Vimal Mishra
#### Are these points locations of weather stations? 

points <- data.frame(long = c(73.625,73.875,73.625,73.375,73.125,73.875,73.625,73.375,73.125,73.875,73.625,73.375),
                     lat = c(21.375,21.125,21.125,21.125,21.125,20.875,20.875,20.875,20.875,20.625,20.625, 20.625)) %>% st_as_sf(coords=c('long','lat'), crs=4326)

# Create 0.25 degree grid
# Note: I made a grid by extending the bounds of your points out by half a cell size in all directions:
cellsize = 0.25
grid_.25 <- st_make_grid(st_as_sfc(
  st_bbox(points) + 
    c(-cellsize/2, -cellsize/2,
      cellsize/2, cellsize/2)),
  what="polygons", cellsize=cellsize) %>% st_sf(grid_id = 1:length(.))

# Create labels for each grid_id
grid_lab <- st_centroid(grid_.25) %>% cbind(st_coordinates(.))

# View the sampled points, polygons and grid
ggplot() +
  geom_sf(data = CI, fill = 'white', lwd = 0.25) +
  geom_sf(data = points, color = 'red', size = 1.7) + 
  geom_sf(data = grid_.25, fill = 'transparent', lwd = 0.3) +
  geom_text(data = grid_lab, aes(x = X, y = Y, label = grid_id), size = 2) +
  coord_sf(datum = 4326)  +
  labs(x = "Longitude") +
  labs(y = "Latitude")
# which grid square is each point in?
points %>% st_join(grid_.25, join = st_intersects) %>% as.data.frame

#### Step 3: Load the climate data for the five points / locations (each covering a grid of 0.5 degrees) ####

library(tidyverse)
library(readr)

### Note: Trying the entire framework for across all locations

## Data comes in the following format:
## Precipitation (mm), Max.Temperature (Celsius), Min.temperature (Celsius), Wind (m/s)

library(data.table)
library(tools) 

# Setting the path where the directory of files exist
file_list <- list.files("D:\\Forest Owlet Project (Jan 2019- August 2020)\\2020_FO_Resurvey_Analysis\\FO_Resurvey_GIS_Analysis\\R_CLimate Plot\\Historical Climate data_Dangs\\Dang_climate_data\\", full.names=T)
file_list
# Looping through the data and reading in the files as a list of lists
dataset <- NULL
for (i in 1:length(file_list)){
  dataset[[i]] <- read_table2(file_list[i], col_names = F)
}  

# Naming each dataset by lat/long as the ID
names(dataset) <- basename(file_path_sans_ext(file_list)) # Using a function from the tools package

# Naming each column for each dataframe within a list
colnames <- c("Precipitation","Max.Temp","Min.Temp","Wind") 
dataset <- lapply(dataset, setNames, colnames)

# Loading in the dataframe of the daily time series (to be merged with the above list of dataframes)
dates <- read.csv("D:\\Forest Owlet Project (Jan 2019- August 2020)\\2020_FO_Resurvey_Analysis\\FO_Resurvey_GIS_Analysis\\R_CLimate Plot\\Historical Climate data_Dangs\\Daily Time Series.csv", header = F)
colnames(dates) <- c("Year","Month","Day")
dataset <- lapply(dataset,bind_cols, dates)


# Creating a summary list of lists that takes the Mean Max.Monthly temp, Mean Min Monthly Temp and Monthly Sum of Precipitation
summary <-  NULL
a <- names(dataset)
for(i in 1:length(dataset)){
  summary[[i]] <- dataset[[a[i]]] %>% group_by(Year, Month) %>% summarise(Mean_Max_Temp = mean(Max.Temp), Mean_Min_Temp = mean(Min.Temp)
                                                                          ,Monthly_Precip = sum(Precipitation))
}

rm(dataset)

# Naming each dataset by lat/long as the ID
names(summary) <- basename(file_list) # Using a function from the tools package


#### Step 4. Visualizations for Climate data - Exploratory Data Analysis ####

# Before we make visualizations, it is easier to bind_rows with a location identified column

data <- NULL
for(i in 1:length(summary)){
  a <- summary[[i]] %>% mutate(location = basename((file_list[i])))
  data <- bind_rows(a,data)
}
rm(a,summary)

data$location[data$location=="data_20.625_73.375"] <- "South-West_Outside_Dang_20.625_73.375"
data$location[data$location=="data_20.625_73.625"] <- "South_Dang__20.625_73.625"
data$location[data$location=="data_20.625_73.875"] <- "South-East_Dang District_20.625_73.875"
data$location[data$location=="data_20.875_73.125"] <- "West_Outside_Dang_20.875_73.125"
data$location[data$location=="data_20.875_73.375"] <- "West_OutsideDang_20.875_73.375 "
data$location[data$location=="data_20.875_73.625"] <- "North-West_Inside_Dang_20.875_73.625"
data$location[data$location=="data_20.875_73.875"] <- "East_Inside_Dang_20.875_73.875"
data$location[data$location=="data_21.125_73.125"] <- "North-West_Outside_Dang_20.125_73.125"
data$location[data$location=="data_21.125_73.375"] <- "North-west_Dang_20.125_73.375"
data$location[data$location=="data_21.125_73.625"] <- "North_Dang_20.125_73.625 "
data$location[data$location=="data_21.125_73.875"] <- "North-East_outside_Dang_20.125_73.875"
data$location[data$location=="data_21.375_73.625"] <- "North_Outside_Dang_20.375_73.625"


## 1. Line plots of Temp (Min and Max) and Precipitation for each month across all locations over 1870-2018 

## Min and Max Temp plots

## Annual Mean_max_Temp of two years (1988 and 2019) 
ggplot(data%>%filter(Year%in% c(1988, 2019)), aes(x=as.factor(Year), y=Mean_Max_Temp, color=as.factor(Year)))+
  geom_boxplot(width=0.5,lwd=1)+
  labs(x="Year")+
  labs(y="Mean_Max_Temp in C")

##Monthly Mean_Min_Temp for the two years (1988 and 2019) 
{
  a <- ggplot(filter(data%>%filter(Year%in%c("1988", "2019"))), aes(x=as.factor(Year), y = Mean_Min_Temp, fill = factor(Year))) +
    geom_boxplot() +
    facet_wrap(~Month, scales = "free")+
    labs(x = "Year") +
    labs(y = "Mean_Min_Temp")
  
  dirname <- "D:\\Forest Owlet Project (Jan 2019- August 2020)\\2020_FO_Resurvey_Analysis\\FO_Resurvey_GIS_Analysis\\R_CLimate Plot\\Historical Climate data_Dangs\\Output\\Mean_Min_Temp\\"
  
  png(filename= file.path(dirname, paste("Month",i, ".png", sep = "")), 
      units="px", 
      width=1920, 
      height=1137,
      res=96,
      type="cairo")
  
  print(a)
  dev.off()
  }


##Monthly Mean_Max_Temp for the two years (1988 and 2019) 
{
  a <- ggplot(filter(data%>%filter(Year%in%c("1988", "2019"))), aes(x=as.factor(Year), y = Mean_Max_Temp, fill = factor(Year))) +
    geom_boxplot() +
    facet_wrap(~Month, scales= "free")+
    labs(x = "Year") +
    labs(y = "Mean_Max_Temp")
  
  dirname <- "D:\\Forest Owlet Project (Jan 2019- August 2020)\\2020_FO_Resurvey_Analysis\\FO_Resurvey_GIS_Analysis\\R_CLimate Plot\\Historical Climate data_Dangs\\Output\\Mean_Max_Temp\\"
  
  png(filename= file.path(dirname, paste("Month",i, ".png", sep = "")), 
      units="px", 
      width=1920, 
      height=1137,
      res=96,
      type="cairo")
  
  print(a)
  dev.off()
}

## Monthly precipitation plots

##Monthly Mean_Max_Temp for the two years (1988 and 2019) 
{
  a <- ggplot(filter(data%>%filter(Year%in%c("1988", "2019"))), aes(x=as.factor(Year), y = Monthly_Precip, fill = factor(Year))) +
    geom_boxplot() +
    facet_wrap(~Month, scales= "free")+
    labs(x = "Year") +
    labs(y = "Monthly precipitation")
  
  dirname <- "D:\\Forest Owlet Project (Jan 2019- August 2020)\\2020_FO_Resurvey_Analysis\\FO_Resurvey_GIS_Analysis\\R_CLimate Plot\\Historical Climate data_Dangs\\Output\\Precipitation\\"
  
  png(filename= file.path(dirname, paste("Month",i, ".png", sep = "")), 
      units="px", 
      width=1920, 
      height=1137,
      res=96,
      type="cairo")
  
  print(a)
  dev.off()
}

a <- ggplot(filter(data%>%filter(Year%in%c("1988", "2019"))), aes(x=as.factor(Year), y = Mean_Max_Temp, fill = factor(Year))) +
  geom_boxplot() +
  facet_wrap(~Month, scales = "free")+
  labs(x = "Year") +
  labs(y = "Mean_Max_Temp")
a
