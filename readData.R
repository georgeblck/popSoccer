# clear workspace
rm(list=ls())
# load packages
library(formatR)
library(countrycode)


# read and format data
rawLines <- readLines("data/elo17.txt")
splitLines <- split(rawLines, ceiling(seq_along(rawLines)/15))
formatedLines <- as.data.frame(do.call("rbind", splitLines),stringsAsFactors = FALSE)
colnames(formatedLines) <- c("rank17", "Name", "elo17",
                             "highRank", "highElo", 
                             "avgRank", "avgElo",
                             "lowRank", "lowElo",
                             "chgRank1y", "chgElo1y",
                             "chgRank5y", "chgElo5y",
                             "chgRank10y", "chgElo10y")
# Formated the plus and minus symbols
formatedLines[,grep("^chg", colnames(formatedLines))] <- apply(formatedLines[,grep("^chg", colnames(formatedLines))],2,FUN=function(x){
  temp <- gsub("\\+", "", x)
  temp <- gsub("^−$", NA, temp)
  return(gsub("−", "-", temp))
})
# Make the important variables numeric
formatedLines[,-2] <- sapply(formatedLines[,-2], as.numeric)
eloDat <- formatedLines
rm(splitLines, rawLines, formatedLines)

# Transform data
eloDat$rank07 <- eloDat$rank17 + eloDat$chgRank10y
eloDat$elo07 <- eloDat$elo17 - eloDat$chgElo10y
head(eloDat)