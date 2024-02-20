#!/usr/bin/Rscript

library(SRAdb)
library(taxizedb)
library(tidyverse)
library(feather)
library(argparse)

parser <- ArgumentParser(description= 'Get metadata from NCBI')
parser$add_argument('--database', '-d', help= 'Specify path to NCBI .sqlite file if already downloaded')
parser$add_argument('--taxon_id', '-id', help= 'NCBI Taxon id of branch you want all species from')
parser$add_argument('--output', '-o', help= 'Specify path to output feather file')
xargs<- parser$parse_args()

database_loc <- xargs$database
user_input <- xargs$taxon_id
output <- xargs$output


if (file.exists(database_loc)) {
  cat("Database file specified. \n")
  sqlfile <- file.path(database_loc)
} else {
  cat("Database file not specified. Downloading the file...\n")
  # https://gbnci.cancer.gov/backup/SRAmetadb.sqlite.gz
  # https://gbnci.cancer.gov/backup/
  sqlfile <- getSRAdbFile()
}
sra_con <- dbConnect(SQLite(),sqlfile)


check_rank <- function (taxon_id) {
  if (taxid2rank(taxon_id) == 'species') {
    return(as.character(taxon_id))
  } else {
    down <- taxizedb::downstream(taxon_id, db="ncbi", downto='species', verbose=FALSE)
    down_items <- unlist(down[[as.character(taxon_id)]][['childtaxa_id']])
    return(down_items)
  }
}

taxon_ids <- user_input %>%
  strsplit(" ") %>%
  lapply(as.numeric) %>%
  unlist() %>%
  map(check_rank) %>%
  unlist() %>%
  paste(collapse = ', ')


sql_query <- sprintf(
  "SELECT *
  FROM sra
  WHERE taxon_id IN (%s)
    AND library_strategy = 'WGS'
    AND library_source = 'GENOMIC'
    AND (
      (platform = 'ILLUMINA' AND library_layout = 'PAIRED - ')
      OR platform = 'OXFORD_NANOPORE'
      OR platform = 'PACBIO_SMRT'
    );", taxon_ids)

cat('Running query... \n')
# This can take a while...
sra_info <- dbGetQuery(sra_con, sql_query)
cat('Finished query! \n')

sra_df <- sra_info %>%
  as_tibble() %>%
  mutate_at(vars(taxon_id), list(scientific_name = ~taxid2name(.))) %>%
  dplyr::select(-which(apply(is.na(.), 2, all)))

write_feather(sra_df, output)
cat('Wrote file, \n')

dbDisconnect(sra_con)