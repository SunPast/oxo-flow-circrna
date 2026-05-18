#!/usr/bin/env Rscript
# Aggregate circRNA detection results from multiple methods
# Usage: Rscript aggregate_beds.R <input_dir> <output_dir> [gtf_file] [common_py] [sample]
# If sample is provided, only process that sample; otherwise process all samples

library(data.table)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
    stop("Usage: Rscript aggregate_beds.R <input_dir> <output_dir> [gtf_file] [common_py] [sample]")
}

InDir <- args[1]
OutDir <- args[2]
GTF <- if (length(args) >= 3 && args[3] != "") args[3] else NULL
commonPy <- if (length(args) >= 4 && args[4] != "") args[4] else file.path(dirname(OutDir), "scripts", "common.py")
target_sample <- if (length(args) >= 5 && args[5] != "") args[5] else NULL

stopifnot(dir.exists(InDir))
if (!dir.exists(OutDir)) dir.create(OutDir, recursive = TRUE)
if (is.null(GTF) || !file.exists(GTF)) stop("GTF file required")
if (!file.exists(commonPy)) stop(paste("common.py not found:", commonPy))

message("Reading GTF annotation...")
gtf_data <- fread(GTF, header = FALSE, sep = "\t", na.strings = c(".", "NA"))
gtf_data <- gtf_data[V3 == "gene"]
gtf_data[, c("gene_id", "gene") := {
    attrs <- tstrsplit(V9, "; ")
    gene_id <- gsub('"', '', attrs[grep("^gene_id", attrs)])
    gene <- gsub('"', '', attrs[grep("^gene_name", attrs)])
    list(gene_id = gene_id, gene = gene)
}, by = 1:nrow(gtf_data)]
gtf_data <- unique(gtf_data[, list(chr = V1, start = V4, end = V5,
    gene_id = substr(sub("gene_id ", "", gene_id), 1, 15),
    gene = sub("gene_name ", "", gene))])

methods <- c("circexplorer2", "circRNA_finder", "CIRI", "find_circ")

# Determine which samples to process
if (!is.null(target_sample)) {
    sample_ids <- target_sample
    message("Processing single sample: ", target_sample)
} else {
    fileList <- list.files(InDir, pattern = "\\.bed$", full.names = TRUE)
    fileList <- fileList[file.info(fileList)$size > 0]
    sample_ids <- unique(gsub("\\.bed$", "", basename(fileList)))
    for (suffix in methods) sample_ids <- gsub(paste0("\\.", suffix, "$"), "", sample_ids)
    sample_ids <- unique(sample_ids)
    message("Processing ", length(sample_ids), " samples")
}

overlaps <- function(x, y) {
    x <- as.data.table(x); y <- as.data.table(y)
    colnames(x)[1:3] <- colnames(y)[1:3] <- c("chr", "start", "end")
    setkey(y, chr, start, end)
    foverlaps(x, y)[!is.na(start)]
}

aggr_circRNA_beds <- function(sample, methods) {
    bed_files <- file.path(InDir, paste0(sample, ".", methods, ".bed"))
    nonexists <- !file.exists(bed_files)

    if (sum(!nonexists) < 2) {
        message("  Skipping ", sample, ": only ", sum(!nonexists), " method(s) available")
        return(invisible(NULL))
    }

    message("  Processing ", sample, "...")
    cmd <- paste("cat", paste(bed_files[!nonexists], collapse = " "),
                 "|", commonPy, "-t 2 -d 0", ">", file.path(OutDir, paste0(sample, ".common.txt")))
    system(cmd, ignore.stdout = TRUE, ignore.stderr = TRUE)

    common_file <- file.path(OutDir, paste0(sample, ".common.txt"))
    if (!file.exists(common_file) || file.info(common_file)$size == 0) {
        message("    No common circRNAs for ", sample)
        return(invisible(NULL))
    }

    bed_common <- tryCatch(
        fread(common_file, header = FALSE, sep = "\t"),
        error = function(e) NULL
    )
    unlink(common_file)

    if (is.null(bed_common) || nrow(bed_common) == 0) {
        message("    No common circRNAs for ", sample)
        return(invisible(NULL))
    }

    colnames(bed_common) <- c("chr", "start", "end")
    bed_common <- bed_common[chr %in% paste0("chr", c(1:22, "X", "Y"))]
    if (nrow(bed_common) == 0) {
        message("    No valid chromosomes for ", sample)
        return(invisible(NULL))
    }

    bed_list <- lapply(methods[!nonexists], function(m) {
        f <- file.path(InDir, paste0(sample, ".", m, ".bed"))
        d <- tryCatch(
            fread(f, select = if (m == "CIRI") c(1:4, 7) else 1:5, header = FALSE, sep = "\t"),
            error = function(e) NULL
        )
        if (is.null(d) || nrow(d) == 0) return(NULL)
        d$tool <- m
        d
    })
    bed_dt <- rbindlist(bed_list, use.names = FALSE)

    if (is.null(bed_dt) || nrow(bed_dt) == 0) {
        message("    No BED data for ", sample)
        return(invisible(NULL))
    }

    colnames(bed_dt) <- c("chr", "start", "end", "strand", "count", "tool")
    bed_dt <- bed_dt[!is.na(count)]

    bed_dt[, id := paste(chr, start, end, sep = "-")]
    bed_common[, id := paste(chr, start, end, sep = "-")]

    annot <- unique(overlaps(bed_common, gtf_data)[, .(id, gene_id, gene, ovp_len = fcase(
        i.start <= start, i.end - start + 1,
        i.end >= end, end - i.start + 1,
        i.start > start, i.end - i.start + 1))])
    annot <- annot[, list(gene = gene[which.max(ovp_len)]), by = .(id)]

    bed_dt2 <- merge(bed_dt, annot, by = "id", all.x = FALSE, all.y = TRUE)
    solid_ids <- bed_dt2[, .(N = sum(as.numeric(count) >= 2)), by = .(id)][N >= 1]$id

    if (length(solid_ids) == 0) {
        message("    No high-confidence circRNAs for ", sample)
        return(invisible(NULL))
    }

    bed_dt2 <- bed_dt2[id %in% solid_ids]
    bed_dt2$id <- NULL
    rv <- bed_dt2[, .(tool = paste(tool, collapse = ","), count = mean(as.numeric(count), na.rm = TRUE)),
                  by = .(chr, start, end, strand, gene)]
    rv$sample <- sample
    fwrite(rv, file = file.path(OutDir, paste0(sample, ".aggr.txt")), sep = "\t")
    message("    Written ", nrow(rv), " circRNAs for ", sample)
}

for (sample in sample_ids) aggr_circRNA_beds(sample, methods)
message("Done. Output: ", OutDir)
