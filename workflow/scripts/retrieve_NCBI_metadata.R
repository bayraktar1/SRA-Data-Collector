#!/usr/bin/env Rscript

library(SRAdb)
library(taxizedb)
library(tidyverse)
library(feather)
library(argparse)

parser <- ArgumentParser(description= 'Get metadata from NCBI')
parser$add_argument('--database', '-d', help= 'Specify path to NCBI .sqlite file if already downloaded')
parser$add_argument('--taxon_id_file', '-t', help= 'File wth NCBI Taxon ids separated by tabs')
parser$add_argument('--accession_file', '-a', help= 'NCBI accessions file')
parser$add_argument('--output', '-o', help= 'Specify path to output feather file')
xargs<- parser$parse_args()

database_loc <- xargs$database
user_input_taxon <- xargs$taxon_id_file
user_input_accession <- xargs$accession_file
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

taxon_ids <- readLines(user_input_taxon) %>%
  strsplit(" ") %>%
  lapply(as.numeric) %>%
  unlist() %>%
  map(check_rank) %>%
  unlist() %>%
  paste(collapse = ', ')

accessions <- readLines(user_input_accession) %>%
  strsplit(" ") %>%
  unlist() %>%
  paste0('"', ., '"', collapse = ", ")


sql_query <- sprintf(
  "SELECT *
  FROM sra
  WHERE taxon_id IN (%s) OR study_accession IN (%s) OR run_accession in (%s)
    AND library_strategy = 'WGS'
    AND library_source = 'GENOMIC'
    AND (
      (platform = 'ILLUMINA' AND library_layout LIKE '%%PAIRED%%')
      OR platform = 'OXFORD_NANOPORE'
      OR platform = 'PACBIO_SMRT'
    );", taxon_ids, accessions, accessions)

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