#!/usr/bin/env Rscript
# Aggregate circRNA results across multiple samples
# Usage: Rscript aggregate_dataset.R <input_dir> <output_dir> [sample_list]

library(data.table)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
    stop("Usage: Rscript aggregate_dataset.R <input_dir> <output_dir> [sample_list]")
}

InDir <- args[1]
OutDir <- args[2]
AllSampleList <- if (length(args) >= 3) args[3] else NULL

stopifnot(dir.exists(InDir))
if (!dir.exists(OutDir)) dir.create(OutDir, recursive = TRUE)

message("Scanning result files...")
fileList <- list.files(InDir, pattern = "aggr\\.txt$", full.names = TRUE)
fileList <- fileList[file.info(fileList)$size > 0]
if (length(fileList) == 0) stop("No aggregation files found")

sample_ids <- gsub("\\.aggr\\.txt$", "", basename(fileList))
message("Samples: ", length(sample_ids))

if (!is.null(AllSampleList) && file.exists(AllSampleList)) {
    all_df <- fread(AllSampleList, header = FALSE, sep = "\t")
    diff_samples <- setdiff(all_df[[1]], sample_ids)
    if (length(diff_samples) > 0) message("Missing samples: ", paste(diff_samples, collapse = ", "))
}

message("Merging results...")
AllData <- rbindlist(lapply(fileList, fread))
AllData[, id := paste(gene, strand, chr, start, end, sep = ":")]
AllData[, tool := "four_methods"]
AllData <- dcast(AllData, id + gene + strand + chr + start + end + tool ~ sample, value.var = "count", fill = 0)
colnames(AllData)[1:7] <- c("id", "gene", "strand", "chrom", "startUpBSE", "endDownBSE", "tool")

if (!is.null(AllSampleList) && file.exists(AllSampleList) && length(diff_samples) > 0) {
    message("Filling missing samples with 0...")
    AllData[, (diff_samples) := 0]
}

out_path <- file.path(OutDir, paste0(basename(InDir), "_circRNA.tsv.gz"))
fwrite(AllData, file = out_path, sep = "\t")
message("Output: ", out_path)
message("Total circRNAs: ", nrow(AllData))
