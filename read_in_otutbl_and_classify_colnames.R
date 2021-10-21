#Read in sample names from OTU table, categorize them into groups (data pools).

setwd("/home/laur/Desktop/NC_filtering_complex_OTU_table/")
setwd("/home/laur/Schreibtisch/NC_filtering_complex_OTU_table/")
#I manually removed the top left cell, #OTU_ID, first.
data <- read.table("otu_table_mod.csv", sep="\t", header=T, row.names = 1)
head(data)
names(data)

p1 <- names(data[which(grepl("run2016", names(data)))])
p1_splnames <- sub("run2016_", "", p1)
length(p1_splnames)
length(unique(p1_splnames))

p2019 <- names(data[which(grepl("run2019", names(data)))])
p2019[1]
strsplit(p2019[1], "_")
sapply(strsplit(p2019[1], "_"), "[", c(1,2) )
sapply(strsplit(p2019, "_"), "[", c(1,2) )
runs <- unique(lapply(strsplit(p2019, "_"), "[", c(1,2) ))
unlist(runs)
lapply(runs, paste, collapse="_")
runnames <- unlist(lapply(runs, paste, collapse="_"))

splnames_run2019_12 <- p2019[which(grepl("run2019_12", p2019))]
splnames_run2019_14 <- p2019[which(grepl("run2019_14", p2019))]
splnames_run2019_15 <- p2019[which(grepl("run2019_15", p2019))]
splnames_run2019_16 <- p2019[which(grepl("run2019_16", p2019))]


