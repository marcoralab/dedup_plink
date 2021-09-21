suppressPackageStartupMessages(library(dplyr))
library(vroom)
suppressPackageStartupMessages(library(glue))

message("Reading bim")
bim <- snakemake@input[[1]] %>%
  vroom(
    col_names = c("CHR", "ID", "CM", "POS", "A1", "A2"),
    col_types = "cciicc")

message("Finding dup IDs")
dups <- bim %>%
  count(ID) %>%
  filter(n > 1) %>%
  pull(ID)

message("Deduplicating bim IDs")
bim_dedup <- bim %>%
  mutate(was_dup = ID %in% dups,
         ID = ifelse(was_dup, glue("{ID}_{A2}_{A1}"), ID))

message("Checking for remaining dup IDs")
dups_remaining <- bim_dedup %>%
  filter(was_dup) %>%
  count(ID) %>%
  filter(n > 1) %>%
  select(ID)

message(glue("{nrow(dups_remaining)} duplicates remaining."))

message("Writing outputs")
dups_remaining %>%
  vroom_write(snakemake@output[["rem"]], col_names = F, delim = "\t")

bim_dedup %>%
  vroom_write(snakemake@output[["bim"]], col_names = F, delim = "\t")
