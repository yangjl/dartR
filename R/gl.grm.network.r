#' @name gl.grm.network
#' @title Represents a genomic relationship matrix (GRM) as a network
#' @description 
#' This script takes a G matrix generated by \code{\link{gl.grm}} and represents the 
#' relationship among the specimens as a network diagram. In order to use this 
#' script, a decision is required on a threshold for relatedness to be 
#' represented as link in the network, and on the layout used to create the diagram.
#'
#' @param G A genomic relationship matrix (GRM) generated by \code{\link{gl.grm}} [required].
#' @param x A genlight object from which the G matrix was generated [required].
#' @param method One of fr, kk, gh or mds [default fr].
#' @param node.size Size of the symbols for the network nodes [default 6].
#' @param node.label TRUE to display node labels [default TRUE].
#' @param node.label.size Size of the node labels [default 3].
#' @param node.label.color Color of the text of the node labels [default "black"].
#' @param relatedness_factor Factor of relatedness[default 0.5].
# @param alpha Upper threshold to determine which links between nodes to display [default 0.995].
#' @param title Title for the plot [default "Network based on genomic relationship matrix"].
#' @param palette_discrete A discrete palette for the color of populations or a 
#' list with as many colors as there are populations in the dataset
#'  [default discrete_palette].
#' @param save2tmp If TRUE, saves any ggplots and listings to the session 
#' temporary directory (tempdir) [default FALSE].
#' @param verbose Verbosity: 0, silent or fatal errors; 1, begin and end; 2,
#'  progress log ; 3, progress and results summary; 5, full report 
#'  [default 2 or as specified using gl.set.verbosity].
#'
#' @details 
#' As identity by descent is not an absolute state, but is relative to a reference 
#' population for which there is generally little information, we can estimate 
#' the kinship of a pair of individuals only relative to some other quantity 
#' (Goudet et al., 2018). In this script, we use the average inbreeding coefficient 
#' (1-f) of the diagonal elements as the reference value. This reference value is 
#' then subtracted from the inbreeding coefficient of each pair of distinct 
#' individuals. This approach is similar to the used by Goudet et al. (2018).
#' 
#' Four layout options are implemented in this function:
#'\itemize{
#'\item "fr" Fruchterman-Reingold layout  \link[igraph]{layout_with_fr} (package igraph)
#'\item "kk" Kamada-Kawai layout \link[igraph]{layout_with_kk} (package igraph)
#'\item "gh" Graphopt layout \link[igraph]{layout_with_graphopt} (package igraph)
#'\item "mds" Multidimensional scaling layout \link[igraph]{layout_with_mds} (package igraph)
#' }
#' 
#' The threshold for relatedness to be represented as a link in the network is 
#' specified as a quantile. Those relatedness measures above the quantile are
#' plotted as links, those below the quantile are not. Often you are looking
#'  for relatedness outliers in comparison with the overall relatedness among 
#'  individuals, so a very conservative quantile is used (e.g. 0.004), but 
#'  ultimately, this decision is made as a matter of trial and error. One way to
#'   approach this trial and error is to try to achieve a sparse set of links 
#'   between unrelated 'background' individuals so that the stronger links are 
#'   preferentially shown.
#' 
#' @return A network plot showing relatedness between individuals 
#' @author Custodian: Arthur Georges -- Post to \url{https://groups.google.com/d/forum/dartr}
#' @examples
#' gl_test <- bandicoot.gl
#' # five populations in gl_test
#' nPop(gl_test)
#' # color list for population colors 
#' pop_colours <- c("deepskyblue","green","gray","orange","deeppink")
#' G_out <- gl.grm(gl_test,plotheatmap=FALSE)
#' gl.grm.network(G_out, gl_test, palette_discrete = pop_colours, relatedness_factor = 0.25)  
#'@references 
#'\itemize{
#'\item Goudet, J., Kay, T., & Weir, B. S. (2018). How to estimate kinship. 
#'Molecular Ecology, 27(20), 4121-4135. 
#'  }
#' @seealso \code{\link{gl.grm}}
#' @family inbreeding functions
#' @export

##@import igraph
gl.grm.network <- function(G, 
                           x,
                           method = "fr", 
                           node.size = 6, 
                           node.label = TRUE, 
                           node.label.size = 2, 
                           node.label.color = "black",
                           relatedness_factor = 0.25,
                           # alpha = 0.004, 
                           title = "Network based on a genomic relationship matrix", 
                           palette_discrete = discrete_palette,
                           save2tmp = FALSE,
                           verbose = NULL){
  
  # SET VERBOSITY
  verbose <- gl.check.verbosity(verbose)
  
  # FLAG SCRIPT START
  funname <- match.call()[[1]]
  utils.flag.start(func=funname,build="Jody",verbosity=verbose)
  
  # CHECK DATATYPE 
  datatype <- utils.check.datatype(x,verbose=verbose)
  
  # FUNCTION SPECIFIC ERROR CHECKING
  # Set a population if none is specified (such as if the genlight object has been generated manually)
  if (is.null(pop(x)) | is.na(length(pop(x))) | length(pop(x)) <= 0) {
    if (verbose >= 2){ 
      cat(important("  Population assignments not detected, individuals assigned to a single population labelled 'pop1'\n"))
    }
    pop(x) <- array("pop1",dim = nInd(x))
    pop(x) <- as.factor(pop(x))
  }
  
  # check if package is installed
  pkg <- "igraph"
  if (!(requireNamespace(pkg, quietly = TRUE))) {
    stop(error("Package",pkg," needed for this function to work. Please install it.")) 
         }

  if (!(method=="fr" || method=="kk" || method=="gh"|| method=="mds")) {
    cat(warn("Warning: Layout method must be one of fr, or kk, gh or mds, set to fr\n"))
    method <- "fr"
  }
  
  # DO THE JOB    
  G2 <- G
  G2[upper.tri(G2,diag = T)]  <- NA
  links <- as.data.frame(as.table(G2))
  links <- links[which(!is.na(links$Freq)),]
  
  colnames(links) <- c("from","to","weight")
  
  # using the average inbreeding coefficient (1-f)
  # of the diagonal elements as the reference value
  MS <- mean(diag(G)-1)
  
  links$kinship <- (links$weight/2) - MS

  nodes <- data.frame(cbind(x$ind.names, as.character(pop(x))))
  colnames(nodes) <- c("name","pop")
  
  network <- igraph::graph_from_data_frame(d=links, vertices=nodes, directed=FALSE)

  # q <- stats::quantile(links$weight, p = 1-alpha)
  # network.FS <- igraph::delete_edges(network, igraph::E(network)[links$weight < q ])
  q <- relatedness_factor
  network.FS <- igraph::delete_edges(network, igraph::E(network)[links$kinship < q ])
  
  if (method=="fr"){
    layout.name <- "Fruchterman-Reingold layout"
    plotcord <- data.frame(igraph::layout_with_fr(network.FS))
  }
  
  if (method=="kk"){
    layout.name <- "Kamada-Kawai layout"
    plotcord <- data.frame(igraph::layout_with_kk(network.FS))
  }
  
  if (method=="gh"){
    layout.name <- "Graphopt layout"
    plotcord <- data.frame(igraph::layout_with_graphopt(network.FS))
  }

  if (method=="mds"){
    layout.name <- "Multidimensional scaling layout"
    plotcord <- data.frame(igraph::layout_with_mds(network.FS))
  }
  
  #get edges, which are pairs of node IDs
  edgelist <- igraph::get.edgelist(network.FS,names = F)
  #convert to a four column edge data frame with source and destination coordinates
  edges <- data.frame(plotcord[edgelist[,1],], plotcord[edgelist[,2],])
  #using kinship for the size of the edges
  edges$size <- links[links$kinship > q, "kinship"]
  X1 <- X2 <- Y1<- Y2 <- label.node <- NA
  colnames(edges) <- c("X1","Y1","X2","Y2","size")
  
  # node labels 
  plotcord$label.node <- igraph::V(network.FS)$name

  # adding populations 
  pop_df <- as.data.frame(cbind(indNames(x),as.character(pop(x))))
  colnames(pop_df) <- c("label.node","pop")
  plotcord <- merge(plotcord,pop_df,by="label.node")
  plotcord$pop <- as.factor(plotcord$pop)
  
  # assigning colors to populations
  if(class(palette_discrete)=="function"){
    colors_pops <- palette_discrete(length(levels(pop(x))))
  }
  
  if(class(palette_discrete)!="function"){
    colors_pops <- palette_discrete
  }
  
  names(colors_pops) <- as.character(levels(x$pop))

  p1 <- ggplot() + 
    geom_segment(data = edges, aes(x = X1, y = Y1, xend = X2, yend = Y2),size=1.5)+    
    geom_point(data=plotcord,aes(x=X1, y=X2,colour=pop),size=node.size) +
    coord_fixed(ratio = 1) +
    theme_void()+
    ggtitle(paste(title,"\n[",layout.name,"]")) +
    theme(legend.position="bottom",plot.title = element_text(hjust = 0.5 ,face="bold", size=14))+
    scale_color_manual(name = "Populations", values = colors_pops)
  
  if(node.label==T){
    p1 <- p1 + geom_text(data=plotcord,aes(x=X1, y=X2,label = label.node),size=node.label.size,show.legend=FALSE,colour=node.label.color) 
  }
  
  # PRINTING OUTPUTS
  print(p1)
  
  # SAVE INTERMEDIATES TO TEMPDIR         
  if(save2tmp){
  # creating temp file names
  temp_plot <- tempfile(pattern = "Plot_")
  match_call <- paste0(names(match.call()),"_",as.character(match.call()),collapse = "_")
  # saving to tempdir
  saveRDS(list(match_call,p1), file = temp_plot)
  if(verbose>=2){
    cat(report("  Saving the ggplot to session tempfile\n"))
    cat(report("  NOTE: Retrieve output files from tempdir using gl.list.reports() and gl.print.reports()\n"))
  }
  }
  
  # RETURN

invisible(p1)
    
}  
