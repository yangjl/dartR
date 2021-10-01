#' @name gl.report.reproducibility
#' @title Report summary of RepAvg (repeatability averaged over both alleles for 
#' each locus) or reproducibility (repeatability of the scores for fragment presence/absence)
#' @description 
#' SNP datasets generated by DArT have an index, RepAvg, generated by reproducing 
#' the data independently for 30% of loci. RepAvg is the proportion of alleles that 
#' give a repeatable result, averaged over both alleles for each locus.
#' 
#' In the case of fragment presence/absence data (SilicoDArT), repeatability is
#' the percentage of scores that are repeated in the technical replicate dataset.
#' 
#' @param x Name of the genlight object containing the SNP or presence/absence
#'  (SilicoDArT) data [required].
#' @param plot.out If TRUE, displays a plot to guide the decision on a filter threshold [default TRUE]
#' @param plot_theme Theme for the plot. See Details for options [default theme_dartR()]
#' @param plot_colors List of two color names for the borders and fill of the plots [default two_colors]
#' @param save2tmp If TRUE, saves any ggplots and listings to the session temporary directory (tempdir) [default FALSE]
#' @param verbose Verbosity: 0, silent or fatal errors; 1, begin and end; 2, progress log ; 
#' 3, progress and results summary; 5, full report [default 2, unless specified using gl.set.verbosity]
#'
#' @details 
#'  The function displays a table of minimum, maximum, mean and quantiles for repeatbility against
#'  possible thresholds that might subsequently be specified in \code{\link{gl.filter.reproducibility}}. 
#'  If plot.out=TRUE, display also includes a boxplot and a histogram to guide in the selection of a threshold 
#'  for filtering on repeatability.
#'
#'  If save2tmp=TRUE, ggplots and relevant tabulations are saved to the session's temp directory (tempdir) 
#'   
#'  For examples of themes, see  \itemize{
#'  \item \url{https://ggplot2.tidyverse.org/reference/ggtheme.html} and \item
#'  \url{https://yutannihilation.github.io/allYourFigureAreBelongToUs/ggthemes/}
#'  }
#'
#' @return An unaltered genlight object
#' @author Custodian: Arthur Georges -- Post to \url{https://groups.google.com/d/forum/dartr}
#'
#' @examples
#' # SNP data
#'   out <- gl.report.reproducibility(testset.gl)
#' # Tag P/A data
#'   out <- gl.report.reproducibility(testset.gs)
#'
#' @seealso \code{\link{gl.filter.reproducibility}}
#' @family filters and filter reports
#' @import patchwork
#' @export

gl.report.reproducibility <- function(x, 
                                      plot.out = TRUE,
                                      plot_theme = theme_dartR(),  
                                      plot_colors = two_colors, 
                                      save2tmp = FALSE,
                                      verbose = NULL) {
  
  # SET VERBOSITY
  verbose <- gl.check.verbosity(verbose)
  
  # FLAG SCRIPT START
  funname <- match.call()[[1]]
  utils.flag.start(func=funname,build="Jody", verbosity =verbose)
  
  # CHECK DATATYPE 
  datatype <- utils.check.datatype(x, verbose=verbose)
  
  # DO THE JOB
  
  ########### FOR METHOD BASED ON LOCUS
  
  # get title for plots
  if (datatype=="SNP"){
    title <- paste0("SNP data (DArTSeq)\nRepeatability by Locus")
  } else {
    title <- paste0("Fragment P/A data (SilicoDArT)\nRepeatability by Locus")
  } 
  
  if (datatype=="SNP"){
    repeatability <- x@other$loc.metrics$RepAvg
  } else {
    repeatability <- x@other$loc.metrics$Reproducibility
  } 
  
  repeatability_plot <- data.frame(repeatability)
  colnames(repeatability_plot) <- "repeatability"
  
  # Boxplot
  if(plot.out){
  p1 <- ggplot(repeatability_plot, aes(y = repeatability)) + 
    geom_boxplot(color = plot_colors[1], fill = plot_colors[2]) + 
    coord_flip() + 
    plot_theme + 
    ylim(c(min(repeatability), 1)) + 
    ylab(" ") + 
    theme(axis.text.y = element_blank(), axis.ticks.y = element_blank()) + 
    ggtitle(title)
  
  # Histogram
  p2 <- ggplot(repeatability_plot, aes(x = repeatability)) + 
    geom_histogram(bins = 50, color = plot_colors[1],fill = plot_colors[2]) + 
    coord_cartesian(xlim = c(min(repeatability),1)) + 
    xlab("Repeatability") + 
    ylab("Count") + 
    plot_theme
  }
  
  # Print out some statistics
  stats <- summary(repeatability)
  cat(report("  Reporting Repeatability by Locus\n"))
  cat("  No. of loci =", nLoc(x), "\n")
  cat("  No. of individuals =", nInd(x), "\n")
  cat("    Minimum      : ", stats[1], "\n")
  cat("    1st quartile : ", stats[2], "\n")
  cat("    Median       : ", stats[3], "\n")
  cat("    Mean         : ", stats[4], "\n")
  cat("    3r quartile  : ", stats[5], "\n")
  cat("    Maximum      : ", stats[6], "\n")
  cat("    Missing Rate Overall: ", round(sum(is.na(as.matrix(x)))/(nLoc(x) * 
                                                                      nInd(x)), 2), "\n\n")
  
  # Determine the loss of loci for a given threshold
  # using quantiles
  quantile_res <- quantile(repeatability, probs = seq(0, 1, 1/20))
  retained <- unlist(lapply(quantile_res, function(y) {res <- length(repeatability[repeatability >= y])}))
  pc.retained <- round(retained * 100/nLoc(x),1)
  filtered <- nLoc(x) - retained
  pc.filtered <- 100 - pc.retained
  df <- data.frame(as.numeric(sub("%", "", names(quantile_res))), 
                   quantile_res, retained, pc.retained, filtered, 
                   pc.filtered)
  colnames(df) <- c("Quantile", "Threshold","Retained", "Percent", "Filtered", "Percent")
  df <- df[order(-df$Quantile), ]
  df$Quantile <- paste0(df$Quantile, "%")
  rownames(df) <- NULL
  
  # PRINTING OUTPUTS
  if(plot.out){
    # using package patchwork
    p3 <- (p1/p2) + plot_layout(heights = c(1, 4))
    print(p3)
  }
  print(df)
  
  # SAVE INTERMEDIATES TO TEMPDIR             
  
  # creating temp file names
  if(save2tmp){
    if(plot.out){
      temp_plot <- tempfile(pattern = "Plot_")
      match_call <- paste0(names(match.call()),"_",as.character(match.call()),collapse = "_")
      # saving to tempdir
      saveRDS(list(match_call,p3), file = temp_plot)
      if(verbose>=2){
        cat(report("  Saving the ggplot to session tempfile\n"))
      }
    }
    temp_table <- tempfile(pattern = "Table_")
    saveRDS(list(match_call,df), file = temp_table)
    if(verbose>=2){
      cat(report("  Saving tabulation to session tempfile\n"))
      cat(report("  NOTE: Retrieve output files from tempdir using gl.list.reports() and gl.print.reports()\n"))
    }
  }
  
  # FLAG SCRIPT END
  
  if (verbose >= 1) {
    cat(report("Completed:", funname, "\n"))
  }
  
  # RETURN
  invisible(x)
  
}
