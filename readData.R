# clear workspace
rm(list = ls())
options(scipen=999)

# load packages
library(formatR)
library(countrycode)
library(wbstats)
library(ggplot2)
library(scales)
library(ggthemes)
library(ggExtra)
library(lubridate)

# Save plots?
savePlots <- FALSE
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
popDat <- rbind.data.frame(popDat, missPopDat)



# merge the data
eloPop <- merge(eloDat, popDat, by = "ccode", all.x = TRUE, all.y = FALSE, sort = FALSE)
# What are the missing values?
eloPop$Name[is.na(eloPop$PopTotal)]

# read & merge the life expectancy data
lifeDat <- read.table("data/WPP2017_Period_Indicators_Medium.csv", sep = ",", header = TRUE, 
                     dec = ".", stringsAsFactors = FALSE)
lifeDat <- lifeDat[(lifeDat$Variant == "Medium") & (lifeDat$MidPeriod == 2013),]
lifeDat$ccode <- countrycode(lifeDat$Location, origin = "country.name", destination = "iso3c")

eloPop <- merge(eloPop, lifeDat, by = "ccode", all.x = TRUE, all.y = FALSE, sort= FALSE)

# Make first graphic in the same vein as reddit
ggplot(data = eloPop, aes(x = PopTotal, y = elo17, col = LEx))+geom_point(size=1.5)+
  scale_x_continuous(trans='log10', breaks = 100*(10^(1:7)),labels=comma) +
  theme_tufte(base_size = 15)+xlab("Population")+ylab("Elo Rating")+geom_smooth(se=FALSE)+
  scale_color_gradient2(midpoint=mean(eloPop$LEx,na.rm = T), low="blue", mid="white",
                        high="darkred", space ="Lab" )
if(savePlots){
  ggsave(filename = paste0("plots/",gsub("[^[:alnum:]=\\.]","", lubridate::now()), ".pdf"), 
         device = cairo_pdf, units = "cm", width = 34, height = 20)
}

# Kendall Correlation
cor.test(eloPop$elo17, eloPop$PopTotal,  method="kendall")
# Marginal Plot
p <- ggplot(eloPop, aes(PopTotal, elo17)) + geom_point() + theme_tufte(ticks=F) +
  theme(axis.title=element_blank())+
  scale_x_continuous(trans='log10', breaks = 100*(10^(1:7)),labels=comma)
ggMarginal(p, type = "histogram", fill = "transparent")
