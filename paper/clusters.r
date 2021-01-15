##devtools::install_github("perishky/eval.save")
library(eval.save)
eval.save.dir(".eval")

top.n <- 1000 ## p_rank in sql query <= 1000

overlaps <- read.table("output/overlaps.txt", sep="\t", stringsAsFactors=F, header=T)

overlaps$n1 <- pmin(top.n, overlaps$n1)
overlaps$n2 <- pmin(top.n, overlaps$n2)

n <- 485000
overlaps$ff <- n - overlaps$n1 - overlaps$n2 + overlaps$overlap
overlaps$tt <- overlaps$overlap
overlaps$tf <- overlaps$n1 - overlaps$overlap
overlaps$ft <- overlaps$n2 - overlaps$overlap

overlaps$p <- eval.save({
  apply(overlaps[,c("ff","ft","tf","tt")], 1, function(vals) {
    fisher.test(matrix(vals, ncol=2), alternative="greater")$p.value
  })
}, "overlaps-p")

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

pdf("output/cell-counts-and-variables.pdf")
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
## [1] 26

subgraphs <- lapply(1:length(clusters), function(i)
                   induced_subgraph(graph, which(membership(clusters)==i)))

subgraphs.weights <- lapply(subgraphs, function(g) E(g)$weight)
subgraphs.weights <- unlist(subgraphs.weights)

quantile(E(graph)$weight)
quantile(subgraphs.weights)
## > quantile(E(graph)$weight)
##          0%         25%         50%         75%        100% 
##  0.05882508  2.16996626  3.16999326  6.91103068 50.00000000 
## > quantile(subgraphs.weights)
##          0%         25%         50%         75%        100% 
##  0.05882508  2.91299251  6.75954040 17.52622106 50.00000000 
threshold
## [1] 6.813747

t(sapply(subgraphs, function(g) {
    c(n=length(V(g)),
      median.weight = median(sapply(V(g), function(v) {
          median(incident(g,v)$weight)
      })))
}))
##         n median.weight
##  [1,] 163      6.156017
##  [2,] 149      2.354872
##  [3,]  18      4.410351
##  [4,]   4     21.362750
##  [5,]   3     26.349518
##  [6,]   3     11.070453
##  [7,]  15     18.822463
##  [8,]   6      5.685741
##  [9,]   3     26.541922
## [10,]  48      9.244293
## [11,] 127      5.434727
## [12,] 112      9.967395
## [13,]  13     20.134970
## [14,]  86     17.572453
## [15,]  13     50.000000
## [16,]   2     21.362750
## [17,]   2      5.083682
## [18,]   2      5.685741
## [19,]   2     21.362750
## [20,]   2     31.257105
## [21,]   2      5.685741
## [22,]   2     16.279071
## [23,]   2      5.685741
## [24,]  24     21.497507
## [25,]   2      5.685741
## [26,]   2      5.685741

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
## > sapply(study.clusters, length)
##  [1] 122 113 100  97  77  15  12  11  10  10   6   6   4   4   4   4   4   3   3
## [20]   3   3   3   3   3   3   2   2   2   2   2   2   2   2   2   2   2   2   2
## [39]   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2   2
## [58]   2   2

study.clusters <- study.clusters[which(sapply(study.clusters,length) > 3)]

subgraphs <- lapply(study.clusters, function(cluster) {
    induced_subgraph(graph, cluster)
})

cbind(n=sapply(subgraphs, vcount),
      deg=sapply(subgraphs, function(g) median(degree(g))),
      pct=sapply(subgraphs, function(g) median(degree(g))/vcount(g)))
##         n  deg       pct
##  [1,] 122 92.0 0.7540984
##  [2,] 113 64.0 0.5663717
##  [3,] 100 84.0 0.8400000
##  [4,]  97 53.0 0.5463918
##  [5,]  77 64.0 0.8311688
##  [6,]  15 14.0 0.9333333
##  [7,]  12 11.0 0.9166667
##  [8,]  11 10.0 0.9090909
##  [9,]  10  6.0 0.6000000
## [10,]  10  8.0 0.8000000
## [11,]   6  5.0 0.8333333
## [12,]   6  5.0 0.8333333
## [13,]   4  3.0 0.7500000
## [14,]   4  3.0 0.7500000
## [15,]   4  3.0 0.7500000
## [16,]   4  2.5 0.6250000
## [17,]   4  3.0 0.7500000

clusters <- do.call(rbind, lapply(1:length(study.clusters), function(i) {
    cbind(cluster=i, study=study.clusters[[i]])
}))

write.csv(clusters, file="output/clusters.csv", row.names=F)


## are there significant links outside clusters?
sapply(subgraphs, function(g) {
  external.edges <- ... ## obtain edges incident on the vertices of 'g' but to vertices outside 'g'
                        ## incident_edges(graph,vertices)
  table(E(g)$weight > threshold)
  table(external.edges$weight > threshold)
})
