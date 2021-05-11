#' Bivariate plot of the results of an ordination generated using gl.pcoa()
#'
#' This script takes output from the ordination generated by gl.pcoa() and plots the individuals classified by population.
#'
#' The factor scores are taken from the output of gl.pcoa() and the population assignments are taken from
#' from the original data file. The specimens are shown in a bivariate plot optionally with adjacent labels
#' and enclosing ellipses. Population labels on the plot are shuffled so as not to overlap (using package \{directlabels\}).
#' This can be a bit clunky, as the labels may be some distance from the points to which they refer, but it provides the
#' opportunity for moving labels around using graphics software (e.g. Adobe Illustrator).
#'
#' Any pair of axes can be specified from the ordination, provided they are within the range of the nfactors value provided to gl.pcoa(). Axes can be scaled to
#' represent the proportion of variation explained. In any case, the proportion of variation explained by each axis is provided in the axis label.
#'
#' Points displayed in the ordination can be identified if the option labels="interactive" is chosen, in which case the resultant plot is
#' ggplotly() friendly. Identification of points is by moving the mouse
#' over them. Refer to the plotly package for further information. 
#'
#' If plot.out=TRUE, returns an object of class ggplot so that layers can subsequently be added; if plot.out=FALSE, returns a dataframe
#' with the individual labels, population labels and PCOA scores for subsequent plotting by the user with ggplot or other plotting software. 
#' 
#' The themes available to format the plot are the following:
#' theme_minimal[1], theme_classic[2],theme_bw[3],theme_gray[4],theme_linedraw[5],theme_light[6],theme_dark[7],theme_economist[8],theme_economist_white[9],theme_calc[10],theme_clean[11],theme_excel[12],theme_excel_new[13],theme_few[14],theme_fivethirtyeight[15],theme_foundation[16],theme_gdocs[17],theme_hc[18],theme_igray[19],theme_solarized[20],theme_solarized_2[21],theme_solid[22],theme_stata[23],theme_tufte[24],theme_wsj[25]
#' Examples of these themes can be consulted in 
#' \url{https://ggplot2.tidyverse.org/reference/ggtheme.html} and \url{https://yutannihilation.github.io/allYourFigureAreBelongToUs/ggthemes/}
#'
#' @param glPca Name of the PCA or PCoA object containing the factor scores and eigenvalues [required]
#' @param x Name of the genlight object or fd object containing the SNP genotypes or 
#' a genlight object containing the Tag P/A (SilicoDArT) genotypes or 
#' the Distance Matrix used to generate the ordination [required]
#' @param scale Flag indicating whether or not to scale the x and y axes in proportion to \% variation explained [default FALSE]
#' @param ellipse Flag to indicate whether or not to display ellipses to encapsulate points for each population [default FALSE]
#' @param p Value of the percentile for the ellipse to encapsulate points for each population [default 0.95]
#' @param labels Flag to specify the labels are to be added to the plot. ["none"|"ind"|"pop"|"interactive"|"legend", default = "pop"]
#' @param theme_plot Theme for the plot. See Details for options [default 4]
#' @param as.pop -- assign another metric to represent populations for the plot [default NULL]
#' @param hadjust Horizontal adjustment of label position [default 1.5]
#' @param vadjust Vertical adjustment of label position [default 1]
#' @param xaxis Identify the x axis from those available in the ordination (xaxis <= nfactors)
#' @param yaxis Identify the y axis from those available in the ordination (yaxis <= nfactors)
#' @param plot.out If TRUE, returns a plot object compatable with ggplot, otherwise returns a dataframe [default TRUE]
#' @param verbose -- verbosity: 0, silent or fatal errors; 1, begin and end; 2, progress log ; 3, progress and results summary; 5, full report [default 2 or as specified using gl.set.verbosity]
#' @return A plot of the ordination [plot.out=TRUE] or a dataframe [plot.out=FALSE]
#' @export
#' @import tidyr 
#' @importFrom methods show
#' @rawNamespace import(ggplot2, except = empty)

#' @author Arthur Georges (Post to \url{https://groups.google.com/d/forum/dartr})
#' @examples
#' if (requireNamespace("directlabels", quietly = TRUE)) {
#' gl <- testset.gl
#' levels(pop(gl))<-c(rep("Coast",5),rep("Cooper",3),rep("Coast",5),
#' rep("MDB",8),rep("Coast",7),"Em.subglobosa","Em.victoriae")
#' pca<-gl.pcoa(gl,nfactors=5)
#' gl.pcoa.plot(pca, gl, ellipse=TRUE, p=0.99, labels="pop",hadjust=1.5,
#'  vadjust=1)
#' if (requireNamespace("plotly", quietly = TRUE)) {
#' #interactive plot to examine labels
#' gl.pcoa.plot(pca, gl, labels="interactive")  
#' }
#' }

gl.pcoa.plot <- function(glPca, 
                         x, 
                         scale=FALSE, 
                         ellipse=FALSE, 
                         p=0.95, 
                         labels="pop",
                         theme_plot=4,
                         as.pop=NULL,
                         hadjust=1.5, 
                         vadjust=1, 
                         xaxis=1, 
                         yaxis=2, 
                         plot.out=TRUE, 
                         verbose=NULL) {
  pkg <- "plotly"
  if (!(requireNamespace(pkg, quietly = TRUE))) {
    stop("Package ",pkg," needed for this function to work. Please install it.") }
  pkg <- "directlabels"
  if (!(requireNamespace(pkg, quietly = TRUE))) {
    stop("Package ",pkg," needed for this function to work. Please install it.") }
   pkg <- "ggrepel"
  if (!(requireNamespace(pkg, quietly = TRUE))) {
    stop("Package ",pkg," needed for this function to work. Please install it.") } 
    pkg <- "ggthemes"
  if (!(requireNamespace(pkg, quietly = TRUE))) {
    stop("Package ",pkg," needed for this function to work. Please install it.") } else {  

# TRAP COMMAND, SET VERSION
  
  funname <- match.call()[[1]]
  build <- "Jacob"
  
# SET VERBOSITY
  
  if(class(x)=="genlight"){
    if (is.null(verbose)){ 
      if(!is.null(x@other$verbose)){ 
        verbose <- x@other$verbose
      } else { 
        verbose <- 2
      }
    }
  }
  if(class(x)=="fd"){
    x <- x$gl
    if (is.null(verbose)){
      verbose <- 2
    }  
  }
  if(class(x)=="dist"){
    if (is.null(verbose)){
      verbose <- 2
    }  
  }
  
  if (verbose < 0 | verbose > 5){
    cat(paste("  Warning: Parameter 'verbose' must be an integer between 0 [silent] and 5 [full report], set to 2\n"))
    verbose <- 2
  }
  
# FLAG SCRIPT START
  
  if (verbose >= 1){
    if(verbose==5){
      cat("Starting",funname,"[ Build =",build,"]\n")
    } else {
      cat("Starting",funname,"\n")
    }
  }
        
# SCRIPT SPECIFIC ERROR CHECKING
  
  if(class(glPca)!="glPca") {
    stop("Fatal Error: glPca object required as primary input (parameter glPca)!\n")
  }
  if(class(x) != "genlight" && class(x) != "dist" && class(x)  != "fd") {
    stop("Fatal Error: genlight, fd or dist object required as secondary input (parameter x)!\n")
  }
  if (labels != "none" && labels != "ind" && labels != "pop" && labels != "interactive" && labels != "legend"){
    cat("  Warning: Parameter 'labels' must be one of none|ind|pop|interactive|legend, set to 'pop'\n")
    labels <- "pop"
  }
  if (p < 0 | p > 1){
    cat("  Warning: Parameter 'p' must fall between 0 and 1, set to 0.95\n")
    p <- 0.95
  }
  if (hadjust < 0 | hadjust > 3){
    cat("  Warning: Parameter 'hadjust' must fall between 0 and 3, set to 1.5\n")
    hadjust <- 1.5
  }
  if (vadjust < 0 | hadjust > 3){
    cat("  Warning: Parameter 'vadjust' must fall between 0 and 3, set to 1.5\n")
    vadjust <- 1.5
  }
  if (xaxis < 1 | xaxis > ncol(glPca$scores)){
    cat("  Warning: X-axis must be specified to lie between 1 and the number of retained dimensions of the ordination",ncol(glPca$scores),"; set to 1\n")
    xaxis <- 1
  }
  if (xaxis < 1 | xaxis > ncol(glPca$scores)){
    cat("  Warning: Y-axis must be specified to lie between 1 and the number of retained dimensions of the ordination",ncol(glPca$scores),"; set to 2\n")
    yaxis <- 2
  }
  
  # Assign the new population list if as.pop is specified
  pop.hold <- pop(x)
  if (!is.null(as.pop)){    
    if(as.pop %in% names(x@other$ind.metrics)){
      pop(x) <- as.matrix(x@other$ind.metrics[as.pop])
      if (verbose >= 2) {cat("  Temporarily setting population assignments to",as.pop,"as specified by the as.pop parameter\n")}
    } else {
      stop("Fatal Error: individual metric assigned to 'pop' does not exist. Check names(gl@other$loc.metrics) and select again\n")
    }
  }
  
# DO THE JOB
  
  # Create a dataframe to hold the required scores
    m <- cbind(glPca$scores[,xaxis],glPca$scores[,yaxis])
    df <- data.frame(m)
    
  # Convert the eigenvalues to percentages
    s <- sum(glPca$eig[glPca$eig >= 0])
    e <- round(glPca$eig*100/s,1)
    
  # Labels for the axes and points
    
    if(class(x)=="genlight"){
      xlab <- paste("PCA Axis", xaxis, "(",e[xaxis],"%)")
      ylab <- paste("PCA Axis", yaxis, "(",e[yaxis],"%)")
      
      ind <- indNames(x)
      pop <- factor(pop(x))
      df <- cbind(df,ind,pop)
      PCoAx <- PCoAy <- NA
      colnames(df) <- c("PCoAx","PCoAy","ind","pop")
      
    } else { # class(x) == "dist"
      xlab <- paste("PCoA Axis", xaxis, "(",e[xaxis],"%)")
      ylab <- paste("PCoA Axis", yaxis, "(",e[yaxis],"%)")
      
      ind <- rownames(as.matrix(x))
      pop <- ind
      df <- cbind(df,ind,pop)
      colnames(df) <- c("PCoAx","PCoAy","ind","pop")
      if(labels == "interactive"){
        cat("  Sorry, interactive labels are not available for an ordination generated from a Distance Matrix\n")
        cat("  Labelling the plot with names taken from the Distance Matrix\n")
      }
      labels <- "pop"
    }  
    # list of themes
    theme_list <- list(
    theme_minimal(),
    theme_classic(),
    theme_bw(),
    theme_gray(),
    theme_linedraw(),
    theme_light(),
    theme_dark(),
    ggthemes::theme_economist(),
    ggthemes::theme_economist_white(),
    ggthemes::theme_calc(),
    ggthemes::theme_clean(),
    ggthemes::theme_excel(),
    ggthemes::theme_excel_new(),
    ggthemes::theme_few(),
    ggthemes::theme_fivethirtyeight(),
    ggthemes::theme_foundation(),
    ggthemes::theme_gdocs(),
    ggthemes::theme_hc(),
    ggthemes::theme_igray(),
    ggthemes::theme_solarized(),
    ggthemes::theme_solarized_2(),
    ggthemes::theme_solid(),
    ggthemes::theme_stata(),
    ggthemes::theme_tufte(),
    ggthemes::theme_wsj())
    
  # If individual labels
    if (labels == "ind") {
      if (verbose>0) cat("  Plotting individuals\n")

    # Plot
      p <- ggplot(df, aes(x=PCoAx, y=PCoAy, group=ind, colour=pop)) +
        geom_point(size=2,show.legend=FALSE) +
        theme_list[theme_plot] +
        ggrepel::geom_text_repel(aes(label = ind),show.legend=FALSE) +
        # directlabels::geom_dl(aes(label=ind),method="first.points") +
        theme(axis.title=element_text(face="bold.italic",size="20", color="black"),
              axis.text.x  = element_text(face="bold",angle=0, vjust=0.5, size=10),
              axis.text.y  = element_text(face="bold",angle=0, vjust=0.5, size=10),
              legend.title = element_text(colour="black", size=18, face="bold"),
              legend.text = element_text(colour="black", size = 16, face="bold")
        ) +
        labs(x=xlab, y=ylab) +
        geom_hline(yintercept=0) +
        geom_vline(xintercept=0)
      # Scale the axes in proportion to % explained, if requested
        if(scale==TRUE) { p <- p + coord_fixed(ratio=e[yaxis]/e[xaxis]) }
      # Add ellipses if requested
        if(ellipse==TRUE) {p <- p + stat_ellipse(aes(colour=pop), type="norm", level=0.95)}
    } 
    
    # If population labels

    if (labels == "pop") {
      if (class(x)=="genlight"){
        if (verbose>0) cat("  Plotting populations\n")
      } else {
        if (verbose>0) cat("  Plotting entities from the Distance Matrix\n")
      }  

      # Plot
      p <- ggplot(df, aes(x=PCoAx, y=PCoAy, group=pop, colour=pop)) +
        geom_point(size=2,aes(colour=pop)) +
        theme_list[theme_plot] +
        directlabels::geom_dl(aes(label=pop),method="smart.grid") +
        theme(axis.title=element_text(face="bold.italic",size="20", color="black"),
              axis.text.x  = element_text(face="bold",angle=0, vjust=0.5, size=10),
              axis.text.y  = element_text(face="bold",angle=0, vjust=0.5, size=10),
              legend.title = element_text(colour="black", size=18, face="bold"),
              legend.text = element_text(colour="black", size = 16, face="bold")
        ) +
        labs(x=xlab, y=ylab) +
        geom_hline(yintercept=0) +
        geom_vline(xintercept=0) +
        theme(legend.position="none")
      # Scale the axes in proportion to % explained, if requested
      if(scale==TRUE) { p <- p + coord_fixed(ratio=e[yaxis]/e[xaxis]) }
      # Add ellipses if requested
      if(ellipse==TRUE) {p <- p + stat_ellipse(aes(colour="black"), type="norm", level=0.95)}
    }
    
  # If interactive labels

    if (labels=="interactive" | labels=="ggplotly") {
      cat("  Displaying an interactive plot\n")
      cat("    NOTE: Returning the ordination scores, not a ggplot2 compatable object\n")
      plot.out <- FALSE

      # Plot
      p <- ggplot(df, aes(x=PCoAx, y=PCoAy)) +
        geom_point(size=2,aes(colour=pop, fill=ind)) +
         theme_list[theme_plot] +
         theme(axis.title=element_text(face="bold.italic",size="20", color="black"),
              axis.text.x  = element_text(face="bold",angle=0, vjust=0.5, size=10),
              axis.text.y  = element_text(face="bold",angle=0, vjust=0.5, size=10),
              legend.title = element_text(colour="black", size=18, face="bold"),
              legend.text = element_text(colour="black", size = 16, face="bold")
        ) +
        labs(x=xlab, y=ylab) +
        geom_hline(yintercept=0) +
        geom_vline(xintercept=0) +
        theme(legend.position="none")
      # Scale the axes in proportion to % explained, if requested
      if(scale==TRUE) { p <- p + coord_fixed(ratio=e[yaxis]/e[xaxis]) }
      # Add ellipses if requested
      if(ellipse==TRUE) {p <- p + stat_ellipse(aes(colour=pop), type="norm", level=0.95)}
       cat("Ignore any warning on the number of shape categories\n")
    }  
    
  # If labels = legend

    if (labels == "legend") {
      if (verbose>0) cat("Plotting populations identified by a legend\n")

      # Plot
      p <- ggplot(df, aes(x=PCoAx, y=PCoAy,colour=pop)) +
        geom_point(size=2,aes(colour=pop)) +
        theme_list[theme_plot] +
        ggrepel::geom_text_repel(aes(label = pop),show.legend=FALSE) +
        theme(axis.title=element_text(face="bold.italic",size="20", color="black"),
              axis.text.x  = element_text(face="bold",angle=0, vjust=0.5, size=10),
              axis.text.y  = element_text(face="bold",angle=0, vjust=0.5, size=10),
              legend.title = element_text(colour="black", size=18, face="bold"),
              legend.text = element_text(colour="black", size = 16, face="bold")
        ) +
        labs(x=xlab, y=ylab) +
        geom_hline(yintercept=0) +
        geom_vline(xintercept=0)
      # Scale the axes in proportion to % explained, if requested
      if(scale==TRUE) { p <- p + coord_fixed(ratio=e[yaxis]/e[xaxis]) }
      # Add ellipses if requested
      if(ellipse==TRUE) {p <- p + stat_ellipse(aes(colour=pop), type="norm", level=0.95)}
    } 
    
    # If labels = none
    
    if (labels == "none" | labels==FALSE) {
      if (verbose>0) cat("Plotting points with no labels\n")

      # Plot
      p <- ggplot(df, aes(x=PCoAx, y=PCoAy,colour=pop)) +
        geom_point(size=2,aes(colour=pop)) +
        theme_list[theme_plot] +
        theme(axis.title=element_text(face="bold.italic",size="20", color="black"),
              axis.text.x  = element_text(face="bold",angle=0, vjust=0.5, size=10),
              axis.text.y  = element_text(face="bold",angle=0, vjust=0.5, size=10),
              legend.title = element_text(colour="black", size=18, face="bold"),
              legend.text = element_text(colour="black", size = 16, face="bold")
        ) +
        labs(x=xlab, y=ylab) +
        geom_hline(yintercept=0) +
        geom_vline(xintercept=0)+
        theme(legend.position="none")
      # Scale the axes in proportion to % explained, if requested
      if(scale==TRUE) { p <- p + coord_fixed(ratio=e[yaxis]/e[xaxis]) }
      # Add ellipses if requested
      if(ellipse==TRUE) {p <- p + stat_ellipse(aes(colour=pop), type="norm", level=0.95)}
    }
    
    if (verbose>0) cat("  Preparing plot .... please wait\n")
    if(labels=="interactive"){
      pp <- plotly::ggplotly(p)
      show(pp)
    } else {
      show(p)
    }
    
# FLAG SCRIPT END
    
    if(plot.out) {
      if(verbose >= 2){cat("  While waiting, returning ggplot compliant object\n")}
    } else {
      if(verbose >= 2){cat("  While waiting, returning dataframe with coordinates of points in the ordinated space\n")}
      df <- data.frame(id=indNames(x), pop=as.character(pop(x)), glPca$scores)
      row.names(df) <- NULL
    }
    
    # Reassign the initial population list if as.pop is specified
    
    if (!is.null(as.pop)){
      pop(x) <- pop.hold
      if (verbose >= 3) {cat("  Resetting population assignments to initial state\n")}
    }
    
    if (verbose >= 1) {
      cat("Completed:",funname,"\n")
    }

  if(plot.out) {
    return(p)
  } else {
    return(df)
  }

  }
}
