#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
package <- args[1]

install.packages(package, dependencies=TRUE)
stopifnot(package %in% installed.packages()[,'Package'])
