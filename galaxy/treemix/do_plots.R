#!/bin/R

source("~/galaxy-dist/tools/OtagoGalaxy/galaxy/treemix/plotting_funcs.R")

dir = commandArgs()

png("galaxy_tree.png")

if (dir[7] == "residual") {
    plot_resid(paste(dir[6], "/galaxy_treemix", sep = ""), dir[8])
} else
    plot_tree(paste(dir[6], "/galaxy_treemix", sep = ""))

dev.off()

