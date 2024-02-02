#!/usr/bin/Rscript

# log <- file(snakemake@log[[1]], open="wt")
# sink(log)

library(SRAdb)
library(taxizedb)
library(tidyverse)
library(magrittr)
library(feather)
library(argparse)

parser <- ArgumentParser(description= 'Get metadata from NCBI')
parser$add_argument('--database', '-d', help= 'Specify path to NCBI .sqlite file if already downloaded')
parser$add_argument('--taxon_id', '-id', help= 'NCBI Taxon id of branch you want all species from')
parser$add_argument('--output', '-o', help= 'Specify path to output feather file')
xargs<- parser$parse_args()

database_loc <- xargs$database
received_taxon_id <- xargs$taxon_id
output <- xargs$output

# database_loc <- snakemake@config[["database"]]
# received_taxon_id <- snakemake@config[["taxon_id"]]
# output <- snakemake@output[[1]]

cat("Database location:", database_loc, "\n")
cat("Output file:", output, "\n")

if (is.null(database_loc)) {
  cat("Database file not specified. Downloading the file...\n")
  sqlfile <- getSRAdbFile()

} else {
  cat("Database file specified. \n")
  sqlfile <- file.path(database_loc)
}

sra_con <- dbConnect(SQLite(),sqlfile)
cat('Established connection to DB file. \n')

enterobacteriaceae_species <- taxizedb::downstream(received_taxon_id, db="ncbi", downto='species', verbose=FALSE)
cat('retrieved species IDs. \n')


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
    );", paste(unlist(enterobacteriaceae_species[[received_taxon_id]][['childtaxa_id']]), collapse = ", "))

cat('Running query... \n')
sra_info <- dbGetQuery(sra_con, sql_query)
cat('Finished query! \n')

sra_df <- sra_info %>%
  as_tibble() %>%
  mutate_at(vars(taxon_id), list(scientific_name = ~taxid2name(.))) %>%
  dplyr::select(-which(apply(is.na(.), 2, all)))
cat('Cleaned df. \n')

write_feather(sra_df, output)
cat('Wrote file, \n')

dbDisconnect(sra_con)
cat('disconnected from db. \n')