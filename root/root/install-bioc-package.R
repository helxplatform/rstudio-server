#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
package <- args[1]

BiocManager::install(package, dependencies=TRUE, update=FALSE, ask=FALSE)
stopifnot(package %in% installed.packages()[,'Package'])
