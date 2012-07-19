#!/bin/R

source("~/galaxy-dist/tools/SOER1000genes/galaxy/treemix/plotting_funcs.R")

dir = commandArgs()

png("galaxy_tree.png")
plot_tree(paste(dir[6], "/galaxy_treemix", sep = ""))
dev.off()
