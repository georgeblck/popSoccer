# clear workspace
rm(list=ls())

# load packages
library(formatR)
library(countrycode)
library(wbstats)

# read and format data
rawLines <- readLines("data/elo17.txt")
splitLines <- split(rawLines, ceiling(seq_along(rawLines)/15))
eloDat <- as.data.frame(do.call("rbind", splitLines),stringsAsFactors = FALSE)
colnames(eloDat) <- c("rank17", "Name", "elo17",
                             "highRank", "highElo", 
                             "avgRank", "avgElo",
                             "lowRank", "lowElo",
                             "chgRank1y", "chgElo1y",
                             "chgRank5y", "chgElo5y",
                             "chgRank10y", "chgElo10y")
# Formated the plus and minus symbols
eloDat[,grep("^chg", colnames(eloDat))] <- apply(eloDat[,grep("^chg", colnames(eloDat))],2,FUN=function(x){
  temp <- gsub("\\+", "", x)
  temp <- gsub("^−$", NA, temp)
  return(gsub("−", "-", temp))
})
# Make the important variables numeric
eloDat[,-2] <- sapply(eloDat[,-2], as.numeric)
# make the countrynames
eloDat$ccode <- countrycode(eloDat$Name, origin = "country.name", destination = "iso3c")
# Manuelle Codes vergeben
eloDat["England","ccode"] <- "GB-ENG"
eloDat["Wales", "ccode"] <- "GB-WLS"
eloDat["Scotland","ccode"] <- "GB-SCT"
eloDat["Zanzibar", "ccode"] <- "Zanzibar"
eloDat["Kosovo","ccode"] <- "GB-ENG"
eloDat["Zanzibar", "ccode"] <- "GB-WLS"
eloDat["Bonaire","ccode"] <- "GB-ENG"
eloDat["Wales", "ccode"] <- "GB-WLS"


# Transform data
eloDat$rank07 <- eloDat$rank17 + eloDat$chgRank10y
eloDat$elo07 <- eloDat$elo17 - eloDat$chgElo10y
head(eloDat)



# get the pop data
# https://population.un.org/wpp/
popDat <- read.table("data/WPP2017_TotalPopulationBySex.csv", sep = ",", header = TRUE,
                     dec=".",stringsAsFactors = FALSE)
popDat <- popDat[(popDat$Time == 2017) & (popDat$Variant == "Medium"),c("Location", "PopTotal")]
popDat$PopTotal <- popDat$PopTotal * 1000
popDat$ccode <- countrycode(popDat$Location, origin = "country.name", destination = "iso3c")
unique(popDat[is.na(popDat$ccode),"Location"])
popDat <- popDat[!is.na(popDat$ccode),]

# merge the data
eloPop <- merge(eloDat, popDat, by = "ccode", all.x = TRUE, all.y = FALSE, sort = FALSE)
