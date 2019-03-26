# clear workspace
rm(list = ls())
options(scipen = 999)

# load packages
library(formatR)
library(countrycode)
library(wbstats)
library(ggplot2)
library(scales)
library(ggthemes)
library(ggExtra)
library(lubridate)
library(readxl)
library(ggrepel)
library(cluster)
library(factoextra)
library(RColorBrewer)
library(jcolors)

# Save plots?
savePlots <- TRUE
# Make all the countrycodes for looking up
ccodes <- codelist_panel

# Read and format the ELO-Data Source: eloratings.net
rawLines <- readLines("data/elo17.txt")
splitLines <- split(rawLines, ceiling(seq_along(rawLines)/15))
eloDat <- as.data.frame(do.call("rbind", splitLines), stringsAsFactors = FALSE)
colnames(eloDat) <- c("rank17", "Name", "elo17", "highRank", "highElo", "avgRank", 
    "avgElo", "lowRank", "lowElo", "chgRank1y", "chgElo1y", "chgRank5y", "chgElo5y", 
    "chgRank10y", "chgElo10y")
# Formated the plus and minus symbols
eloDat[, grep("^chg", colnames(eloDat))] <- apply(eloDat[, grep("^chg", colnames(eloDat))], 
    2, FUN = function(x) {
        temp <- gsub("\\+", "", x)
        temp <- gsub("^−$", NA, temp)
        return(gsub("−", "-", temp))
    })
# Make the important variables numeric
eloDat[, -2] <- sapply(eloDat[, -2], as.numeric)
# Calculate the Elo-Ratings and Ranks 10 Years ago
eloDat$rank07 <- eloDat$rank17 + eloDat$chgRank10y
eloDat$elo07 <- eloDat$elo17 - eloDat$chgElo10y

# make the Country ISO-Codes
eloDat$ccode <- countrycode(eloDat$Name, origin = "country.name", destination = "iso3c")
# What are the non-matching countries
length(unique(eloDat$Name[is.na(eloDat$ccode)]))
unique(eloDat$Name[is.na(eloDat$ccode)])
# Set manual ISO-Codes
eloDat[eloDat$Name == "England", "ccode"] <- "GB-ENG"
eloDat[eloDat$Name == "Wales", "ccode"] <- "GB-WLS"
eloDat[eloDat$Name == "Scotland", "ccode"] <- "GB-SCT"
eloDat[eloDat$Name == "Northern Ireland", "ccode"] <- "GB-NIR"
eloDat[eloDat$Name == "Kurdistan", "ccode"] <- NA
eloDat[eloDat$Name == "Zanzibar", "ccode"] <- "Zanzibar"
eloDat[eloDat$Name == "Kosovo", "ccode"] <- NA
eloDat[eloDat$Name == "Saint Martin", "ccode"] <- "MF"
eloDat[eloDat$Name == "Bonaire", "ccode"] <- "BQ-BO"
eloDat[eloDat$Name == "Chagos Islands", "ccode"] <- "Chagos Islands"
eloDat[eloDat$Name == "Tibet", "ccode"] <- NA



# get the pop data
popDat <- read.table("data/WPP2017_TotalPopulationBySex.csv", sep = ",", header = TRUE, 
    dec = ".", stringsAsFactors = FALSE)
popDat <- popDat[(popDat$Time == 2017) & (popDat$Variant == "Medium"), c("Location", 
    "PopTotal")]
popDat$PopTotal <- popDat$PopTotal * 1000
# Create Country ISO-Codes
popDat$ccode <- countrycode(popDat$Location, origin = "country.name", destination = "iso3c")
# What are the non-matching countries?
unique(popDat[is.na(popDat$ccode), "Location"])
# Remove the non-matching countries
popDat <- popDat[!is.na(popDat$ccode), ]
missPopDat <- data.frame(Location = c("Saint Martin", "England", "Northern Ireland", 
    "Chagos Islands", "Wales", "Zanzibar", "Tibet", "Bonaire", "Kurdistan", "Scotland", 
    "Kosovo", "Saitn Barthélmy"), PopTotal = c(35107, 55619 * 1000, 1870800, 3000, 
    3125200, 1303569, NA, 18905, NA, 5424 * 1000, NA, 9625), ccode = c("MF", "GB-ENG", 
    "GB-NIR", "Chagos Islands", "GB-WLS", "Zanzibar", NA, "BQ-BO", NA, "GB-SCT", 
    NA, "BLM"), stringsAsFactors = FALSE)
# Remove weird China Double
popDat[popDat$Location == "Less developed regions, excluding China",] <- NA
popDat <- rbind.data.frame(popDat, missPopDat)
popDat <- na.omit(popDat)


# merge the data
eloPop <- merge(eloDat, popDat, by = "ccode", all.x = TRUE, all.y = FALSE, sort = FALSE)
# What are the missing values?
eloPop$Name[is.na(eloPop$PopTotal)]
eloPop <- na.omit(eloPop)



# read & merge the life expectancy data
lifeDat <- read.table("data/WPP2017_Period_Indicators_Medium.csv", sep = ",", header = TRUE, 
                      dec = ".", stringsAsFactors = FALSE)
lifeDat <- lifeDat[(lifeDat$Variant == "Medium") & (lifeDat$MidPeriod == 2013), ]
lifeDat$ccode <- countrycode(lifeDat$Location, origin = "country.name", destination = "iso3c")
# Remove China Double
lifeDat[lifeDat$Location == "Less developed regions, excluding China",] <- NA
# What are the nations without ccode?
unique(lifeDat[is.na(lifeDat$ccode), "Location"])
eloPopLife <- merge(eloPop, subset(lifeDat, select=-c(Location,LocID,VarID,Variant,Time,MidPeriod)), by = "ccode", all.x = TRUE, all.y = FALSE, sort = FALSE)



# read social progress index
spi <- read_excel("data/2018-Results.xlsx", sheet = "2018")
bad.socprog <- spi[is.na(countrycode(spi$Code, origin = "iso3c", destination = "iso3c")), 1:3]
#print(unique(bad.socprog))
spi$ccode <- countrycode(spi$Code, "iso3c", "iso3c")
colnames(spi) <- gsub("[[:space:]]", "", colnames(spi))

# merge the data as well
eloPopSPI <-merge(eloPop, subset(spi, select=-c(Country,Code)), by ="ccode", sort = FALSE, all.x = TRUE, all.y = FALSE)

### Create a small data frame of Nations that have all the data
eloDatFinal <- na.omit(eloPopSPI)
