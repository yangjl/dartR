#' Represents a genomic relatedness matrix as a network
#' 
#' This script takes a G matrix generated by gl.grm() and represents the relationship among the specimens as a network diagram. In order to use this script,
#' a decision is required on a threshold for relatedness to be represented as link in the network, and on the layout used to create the diagram.
#' 
#' The threshold for relatedness to be represented as a link in the network is specified as a quantile. Those relatedness measures above the quantile are
#' plotted as links, those below the quantile are not. Often you are looking for relatedness outliers in comparison with the overall relatedness among individuals,
#' so a very conservative quantile is used (e.g. 0.004), but ultimately, this decision is made as a matter of trial and error. One way to approach this trial and error
#' is to try to achieve a sparse set of links between unrelated 'background' individuals so that the stronger links are preferentially shown.
#' 
#' There are several layouts from which to choose. The most popular are given as options in this script.
#' 
#' fr -- Fruchterman, T.M.J. and Reingold, E.M. (1991). Graph Drawing by Force-directed Placement. Software -- Practice and Experience 21:1129-1164.
#' kk -- Kamada, T. and Kawai, S.: An Algorithm for Drawing General Undirected Graphs. Information Processing Letters 31:7-15, 1989. 
#' drl -- Martin, S., Brown, W.M., Klavans, R., Boyack, K.W., DrL: Distributed Recursive (Graph) Layout. SAND Reports 2936:1-10, 2008. 
#' 
#' colors of node symbols are those of the rainbow.
#' 
#'@param G -- a G relatedness matrix generated by gl.grm [required]
#'@param x -- genlight object from which the G matrix was generated [required]
#'@param method -- one of fr, kk or drl [Default:fr]
#'@param node.size -- size of the symbols for the network nodes [default: 3]
#'@param node.label -- TRUE to display node labels [default: FALSE]
#'@param node.label.size -- Size of the node labels [default: 0.7]
#'@param node.label.color -- color of the text of the node labels [default: "black"]
#'@param alpha -- upper threshold to determine which links between nodes to display [default: 0.995]
#'@param title -- title for the plot [default: "Network based on G-matrix of genetic relatedness"]
#'@param verbose -- verbosity. If zero silent, max 3.
#'@return NULL 
#'@importFrom grDevices rgb
#'@importFrom graphics legend plot
#'@export
#'@author Arthur Georges (Post to \url{https://groups.google.com/d/forum/dartr})
#'  
#'@examples
#'#gl.grm.network(G,x)  

#layout_with_kk layout_with_fr layout_with_drl graph_from_data_frame delete_edges V

gl.grm.network <- function(G, 
                           x,
                           method="fr", 
                           node.size=3, 
                           node.label=FALSE, 
                           node.label.size=0.7, 
                           node.label.color="black",
                           alpha=0.004, 
                           title="Network based on G-matrix of genetic relatedness", 
                           verbose=3){

# CHECK IF PACKAGES ARE INSTALLED
  pkg <- "igraph"
  if (!(requireNamespace(pkg, quietly = TRUE))) {
    stop("Package",pkg," needed for this function to work. Please install it.") } 
  
  
  
  if(class(x)!="genlight") {
    cat("Fatal Error: genlight object required for gl.drop.pop.r!\n"); stop("Execution terminated\n")
  }
  if (!(method=="fr" || method=="kk" || method=="drl")) {
    cat("Warning: Layout method must be one of fr, or kk, or drl, set to fr\n")
    method <- "fr"
  }
  if (verbose < 0 | verbose > 5){
    cat("Warning: Verbosity must take on an integer value between 0 and 5, set to 3\n")
    verbose <- 3
  }

  d <- length(G[,1])
  links <- data.frame(array(NA,dim=c((d*d-d)/2,3)))
  count <- 1
  for (i in 1:(d-1)){
    for(j in (i+1):d){
      links[count,1] <- row.names(G)[i]
      links[count,2] <- row.names(G)[j]
      #links[count,2] <- as.character(pop(x))[indNames(x)==row.names(G)[i]]
      links[count,3] <- G[i,j]
      count <- count + 1
    }
  }
  # 
  # G[lower.tri(G)] <- NA
  # links <- as.data.frame(as.table(G))
  # links <- links[which(!is.na(links$Freq)),]
  # 
  # links <- links[which(!is.na(links$Freq) & links$Freq <1 & links$Freq>0.55),]
  # links <- links[order(links$Freq,decreasing = T),]
  
  
  colnames(links) <- c("from","to","weight")
  
  nodes <- data.frame(cbind(x$ind.names, as.character(pop(x))))
  colnames(nodes) <- c("name","pop")
  
  network<-igraph::graph_from_data_frame(d=links, vertices=nodes, directed=FALSE)
  
  colors = rainbow(nlevels(pop(x)))
  my_colors <- colors[pop(x)]
  
  q <- stats::quantile(links$weight, p = 1-alpha)
  network.FS <- igraph::delete_edges(network, igraph::E(network)[links$weight < q ])
  
  if (method=="fr"){
    layout.name <- "Fruchterman-Reingold layout"
    l <- igraph::layout_with_fr(network.FS)
  }
  if (method=="kk"){
    layout.name <- "Kamada-Kawai layout"
    l <- igraph::layout_with_kk(network.FS)
  }
  if (method=="drl"){
    layout.name <- "DrL Graph layout"
    l <- igraph::layout_with_drl(network.FS)
  }
  title <- paste(title,"\n[",layout.name,"]")

  if (node.label) {
    node.label <- igraph::V(network)$name
  } else {
    node.label <- NA
    node.label.size <- NA
    node.label.color <- NA
  }
  
    plot(network.FS, 
       edge.arrow.size=0, 
       edge.curved=0, 
       vertex.size=node.size,
       vertex.color=my_colors,
       vertex.frame.color="#555555",
       vertex.label=node.label,
       vertex.label.color=node.label.color,
       vertex.label.cex=node.label.size,
       layout=l, 
       main = title)
  
    legend("bottomleft", legend=levels(pop(x))  , col = colors , bty = "n", pch=20 , pt.cex = 3, cex = 1, text.col=colors , horiz = FALSE, inset = c(0.1, 0.1))
    
    return(invisible())
  
}  
