output.dir <- "output-20210811"

top.n <- 1000 ## p_rank in sql query <= 1000

##devtools::install_github("perishky/eval.save")
library(eval.save)
eval.save.dir(".eval")

overlaps <- read.table(file.path(output.dir, "overlaps.txt"), sep="\t", stringsAsFactors=F, header=T)

overlaps$n1 <- as.integer(overlaps$n1)
overlaps$n2 <- as.integer(overlaps$n2)

overlaps$n1 <- pmin(top.n, overlaps$n1)
overlaps$n2 <- pmin(top.n, overlaps$n2)

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

## create 'overlap' matrix
studies <- unique(c(overlaps$study1, overlaps$study2))
overlap.p <- matrix(NA, ncol=length(studies), nrow=length(studies),
                   dimnames=list(studies, studies))
idx <- cbind(r=match(overlaps$study1, rownames(overlap.p)),
             c=match(overlaps$study2, colnames(overlap.p)))
overlap.p[idx] <- overlaps$p

log.p <- -log(overlap.p,10)
log.p[which(log.p > 50)] <- 50
threshold <- -log(0.05/length(log.p)*2, 10)

## plot heatmap of log.p
source("heatmap-function.r")

pdf(file.path(output.dir, "cell-counts-and-variables.pdf"))
plot.new()
grid.clip()
cols <- heatmap.color.scheme(low.breaks=seq(0,threshold,length.out=50),
                             high.breaks=seq(threshold,max(log.p,na.rm=T),length.out=50))
h.out <- heatmap.simple(log.p,
                        color.scheme=cols,
                        key.min=0,
			key.max=max(log.p, na.rm=T),
			na.color="gray",
			scale="none",
                        title="...")
 #h.marks <- matrix(0, ncol=ncol(log.p), nrow=nrow(log.p))
 #h.marks[log.p < threshold] <- 1
 #heatmap.mark(h.out, h.marks, mark="box")
 dev.off()


log.p[is.na(log.p)] <- 0

library(igraph)

graph <- graph_from_adjacency_matrix(log.p,
                                     mode="undirected",
                                     weighted=T,
                                     diag=F)
clusters <- cluster_louvain(graph)

length(clusters)
## [1] 112

subgraphs <- lapply(1:length(clusters), function(i)
                   induced_subgraph(graph, which(membership(clusters)==i)))

subgraphs.weights <- lapply(subgraphs, function(g) E(g)$weight)
subgraphs.weights <- unlist(subgraphs.weights)

quantile(E(graph)$weight)
quantile(subgraphs.weights)
## > quantile(E(graph)$weight)
##          0%         25%         50%         75%        100% 
##  0.05882508  2.09858538  3.29871642  6.09151466 50.00000000 
## > quantile(subgraphs.weights)
##          0%         25%         50%         75%        100% 
##  0.05882508  2.68574174  4.84064352 11.10709965 50.00000000 

threshold
## [1] 7.664473

ret <- t(sapply(subgraphs, function(g) {
    c(n=length(V(g)),
      median.weight = median(sapply(V(g), function(v) {
          median(incident(g,v)$weight, na.rm=T)
      })))
}))
## > ret[ret[,"n"] > 2,]
##         n median.weight
##  [1,]  10      5.114917
##  [2,] 324      3.707876
##  [3,]   4     21.362750
##  [4,]   3     26.349518
##  [5,]   3     11.070453
##  [6,]   3      5.685741
##  [7,]  11      9.766727
##  [8,]  12     21.595919
##  [9,] 839      2.385159
## [10,]   5      5.685741
## [11,] 373      4.731499
## [12,]   4      5.309454
## [13,] 160      4.943059
## [14,] 128      7.367725
## [15,] 103     19.201461
## [16,]  22     11.105984
## [17,]   5     17.197919
## [18,]   4      4.857909
## [19,]   3      5.384712


study.ids <- lapply(1:length(subgraphs), function(i) {
    g <- subgraphs[[i]]
    sig.edges <- as_ids(E(g))[which(E(g)$weight > threshold)]    
    g <- subgraph.edges(g, sig.edges, delete.vertices=T)
    components(g)$membership + length(subgraphs)*i
})
study.ids <- unlist(study.ids)

study.clusters <- lapply(unique(study.ids), function(id)
                         names(study.ids)[which(study.ids == id)])

study.clusters <- study.clusters[order(sapply(study.clusters, length), decreasing=T)]

sapply(study.clusters, length)
##   [1] 235 197 168 117 105  81  11   9   8   7   6   5   5   4   4   4   4   4
##  [19]   4   4   4   4   3   3   3   3   3   3   3   3   3   3   3   3   3   3
##  [37]   3   3   3   3   3   2   2   2   2   2   2   2   2   2   2   2   2   2
##  [55]   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2
##  [73]   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2
##  [91]   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2
## [109]   2   2


study.clusters <- study.clusters[which(sapply(study.clusters,length) > 3)]

subgraphs <- lapply(study.clusters, function(cluster) {
    induced_subgraph(graph, cluster)
})

cbind(n=sapply(subgraphs, vcount),
      deg=sapply(subgraphs, function(g) median(degree(g))),
      pct=sapply(subgraphs, function(g) median(degree(g))/vcount(g)))
##         n deg       pct
##  [1,] 235 151 0.6425532
##  [2,] 197  40 0.2030457
##  [3,] 168 119 0.7083333
##  [4,] 117  70 0.5982906
##  [5,] 105  80 0.7619048
##  [6,]  81  75 0.9259259
##  [7,]  11   8 0.7272727
##  [8,]   9   6 0.6666667
##  [9,]   8   7 0.8750000
## [10,]   7   6 0.8571429
## [11,]   6   5 0.8333333
## [12,]   5   4 0.8000000
## [13,]   5   1 0.2000000
## [14,]   4   3 0.7500000
## [15,]   4   3 0.7500000
## [16,]   4   3 0.7500000
## [17,]   4   3 0.7500000
## [18,]   4   2 0.5000000
## [19,]   4   3 0.7500000
## [20,]   4   2 0.5000000
## [21,]   4   2 0.5000000
## [22,]   4   2 0.5000000


clusters <- do.call(rbind, lapply(1:length(study.clusters), function(i) {
    cbind(cluster=i, study=study.clusters[[i]])
}))

write.csv(clusters, file=file.path(output.dir, "clusters.csv"), row.names=F)

