## directory for outputs (plots, csv files, etc.)
output.dir <- "output-20210811"

## consider at most the top 1000 associations reported by each study
top.n <- 1000 ##  p_rank in sql query <= 1000

library(Cairo)
library(readr)
library(randomcoloR)

## package for saving the outputs of computations
## install: devtools::install_github("perishky/eval.save")
library(eval.save)
eval.save.dir(".eval")

## load Hannah's phenotype groups
source("https://raw.githubusercontent.com/hannah-e/collapse_EWAS_catalog_phenotypes/main/functional_analysis_regroup_EWAS_catalogue_phenotypes.R")
## out: EWAS_catalog
groups <- unique(EWAS_catalog[,c("StudyID","phenotype")])
colnames(groups) <- c("study","group")

## read number of overlapping associations per study
overlaps <- read.table(file.path(output.dir, "overlaps.txt"), sep="\t", stringsAsFactors=F, header=T)

overlaps$n1 <- as.integer(overlaps$n1)
overlaps$n2 <- as.integer(overlaps$n2)

overlaps$n1 <- pmin(top.n, overlaps$n1)
overlaps$n2 <- pmin(top.n, overlaps$n2)

## calculate overlap significance using fisher's exact test
## for each pair of studies
n <- 485000
overlaps$ff <- n - overlaps$n1 - overlaps$n2 + overlaps$overlap
overlaps$tt <- overlaps$overlap
overlaps$tf <- overlaps$n1 - overlaps$overlap
overlaps$ft <- overlaps$n2 - overlaps$overlap
overlaps$p <- eval.save({
  apply(overlaps[,c("ff","ft","tf","tt")], 1, function(vals) {
      tryCatch(
          fisher.test(matrix(vals, ncol=2), alternative="greater")$p.value
          , error=function(e) NA)
  })
}, "overlaps-p") ## 20 minutes

## add symmetric comparisons
overlaps.r <- overlaps
overlaps.r$study1 <- overlaps.r$study2
overlaps.r$n1 <- overlaps.r$n2
overlaps.r$study2 <- overlaps$study1
overlaps.r$n2 <- overlaps$n1
overlaps.r$p <- overlaps$p
overlaps <- rbind(overlaps, overlaps.r)

## create 'overlap.p', matrix of fisher exact test p-values
studies <- unique(c(overlaps$study1, overlaps$study2))
overlap.p <- matrix(NA, ncol=length(studies), nrow=length(studies),
                   dimnames=list(studies, studies))
idx <- cbind(r=match(overlaps$study1, rownames(overlap.p)),
             c=match(overlaps$study2, colnames(overlap.p)))
overlap.p[idx] <- overlaps$p

## calculate log of overlap p-values
log.p <- -log(overlap.p,10)
log.p[which(log.p > 50)] <- 50

## Bonferroni adjusted -log(p-value) threshold
threshold <- -log(0.05/length(log.p)*2, 10)
threshold
## [1] 7.664473

## plot heatmap of log.p
source("heatmap-function.r")

CairoPNG(file.path(output.dir, "cell-counts-and-variables.png"),
         width=16384, height=16384)
plot.new()
grid.clip()

cols <- heatmap.color.scheme(
    low.breaks=seq(0,threshold,length.out=50),
    high.breaks=seq(threshold,max(log.p,na.rm=T),length.out=50))

all.groups <- sort(unique(groups[,"group"]))
group.cols <- data.frame(
    group=all.groups,
    col=rainbow(length(all.groups)))
study.cols <- data.frame(
    study=colnames(log.p),
    group=groups$group[match(colnames(log.p), groups$study)])
study.cols$col <- group.cols$col[match(study.cols$group,group.cols$group)]
clinical <- matrix(study.cols$col, nrow=1)
rownames(clinical) <- "phenotype group"

h.out <- heatmap.simple(log.p,
                        color.scheme=cols,
                        key.min=0,
			key.max=max(log.p, na.rm=T),
			na.color="gray",
			scale="none",
                        clinical=clinical,
                        title="EWAS catalog clustering") ## 5 minutes

dev.off() 

## replace missing p-values with p=1
log.p[is.na(log.p)] <- 0





## use networks to identify clusters of studies (louvain clustering)
## VD Blondel, J-L
##     Guillaume, R Lambiotte and E Lefebvre: Fast unfolding of community
##     hierarchies in large networks, <URL:
##     http://arxiv.org/abs/arXiv:0803.0476>
weights <- log.p
weights[which(weights < -log(1e-4,10))] <- 0 

library(igraph)
graph <- graph_from_adjacency_matrix(weights,
                                     mode="undirected",
                                     weighted=T,
                                     diag=F)
clusters <- cluster_louvain(graph)

length(clusters)
## [1] 699

## break the graph unto subgraphs corresponding to clusters
subgraphs <- lapply(1:length(clusters), function(i)
                   induced_subgraph(graph, which(membership(clusters)==i)))

## compare edge weights (i.e. log p-values)
## between nodes/studies in the same
## cluster versus elsewhere
subgraphs.weights <- lapply(subgraphs, function(g) E(g)$weight)
subgraphs.weights <- unlist(subgraphs.weights)
quantile(E(graph)$weight)
quantile(subgraphs.weights)
## > quantile(E(graph)$weight)
##        0%       25%       50%       75%      100% 
##  4.000195  5.083681  7.675126 14.748110 50.000000 
## > quantile(subgraphs.weights)
##        0%       25%       50%       75%      100% 
##  4.000510  5.208620  9.235719 19.081418 50.000000 



## show sizes of clusters and median -log(p-value) per cluster
ret <- t(sapply(subgraphs, function(g) {
    c(n=length(V(g)),
      median.weight = median(sapply(V(g), function(v) {
          median(incident(g,v)$weight, na.rm=T)
      })))
}))
ret <- ret[order(ret[,"n"],decreasing=T),]
ret[ret[,"n"] > 4,]
##        n median.weight
##  [1,] 328      6.608221
##  [2,] 305      8.307027
##  [3,] 192     11.945131
##  [4,] 143      8.381339
##  [5,]  92     16.468290
##  [6,]  79     34.567194
##  [7,]  36      6.513009
##  [8,]  19      5.083682
##  [9,]  12     21.595919
## [10,]  11      9.766727
## [11,]  10     26.784681
## [12,]  10     47.299716
## [13,]   9      5.384712
## [14,]   9     12.937390
## [15,]   8      5.573377
## [16,]   8      4.796666
## [17,]   7      9.514150
## [18,]   6     14.759602
## [19,]   5      5.384712
## [20,]   5      5.685741
## [21,]   5     50.000000
## [22,]   5     17.197919


## median number of neighbors ('deg') within each cluster
ret <- cbind(n=sapply(subgraphs, vcount),
             deg=sapply(subgraphs, function(g) median(degree(g))))
ret <- ret[order(ret[,"n"],decreasing=T),]
ret[ret[,"n"] > 4,]
##        n  deg
##  [1,] 328 90.0
##  [2,] 305  6.0
##  [3,] 192 81.0
##  [4,] 143 54.0
##  [5,]  92 59.0
##  [6,]  79 66.0
##  [7,]  36  3.5
##  [8,]  19  2.0
##  [9,]  12  9.0
## [10,]  11  8.0
## [11,]  10  3.5
## [12,]  10  7.0
## [13,]   9  3.0
## [14,]   9  5.0
## [15,]   8  2.0
## [16,]   8  4.0
## [17,]   7  2.0
## [18,]   6  1.0
## [19,]   5  3.0
## [20,]   5  4.0
## [21,]   5  4.0
## [22,]   5  2.0

clusters <- do.call(rbind, lapply(1:length(subgraphs), function(i) {
    data.frame(cluster=i,
               cluster.size=length(V(subgraphs[[i]])),
               study=names(V(subgraphs[[i]])))
}))
clusters$group <- groups$group[match(clusters$study, groups$study)]

write.csv(clusters, file=file.path(output.dir, "louvain-clusters.csv"), row.names=F)

