#' Report summary of Call Rate for loci or individuals
#'
#' SNP datasets generated by DArT have missing values primarily arising from failure to call a SNP because of a mutation
#' at one or both of the the restriction enzyme recognition sites. This script reports the number of missing values for each
#' of several percentiles. The script gl.filter.callrate() will filter out the loci with call rates below a specified threshold.
#' 
#' Tag Presence/Absence datasets (SilicoDArT) have missing values where it is not possible to determine reliably if there the
#' sequence tag can be called at a particular locus.
#' 
#' The minimum, maximum and mean call rate are provided. Output also is a histogram of read depth, accompanied by a box and 
#' whisker plot presented either in standard (boxplot="standard") or adjusted for skewness (boxplot=adjusted). 
#' 
#' Refer to Tukey (1977, Exploratory Data Analysis. Addison-Wesley) for standard
#' Box and Whisker Plots and Hubert & Vandervieren (2008), An Adjusted Boxplot for Skewed
#' Distributions, Computational Statistics & Data Analysis 52:5186-5201) for adjusted
#' Box and Whisker Plots.
#' 
#' @param x -- name of the genlightobject containing the SNP or presence/absence (SilicoDArT) data [required]
#' @param method specify the type of report by locus (method="loc") or individual (method="ind") [default method="loc"]
#' @param boxplot -- if 'standard', plots a standard box and whisker plot; if 'adjusted',
#' plots a boxplot adjusted for skewed distributions [default 'adjusted']
#' @param range -- specifies the range for delimiting outliers [default = 1.5 interquartile ranges]
#' @param silent -- if FALSE, function returns an object, otherwise NULL [default TRUE]
#' @param verbose -- verbosity: 0, silent or fatal errors; 1, begin and end; 2, progress log ; 3, progress and results summary; 5, full report [default 2]
#' @return if silent==TRUE, returns NULL; otherwise returns a tabulation of CallRate against Threshold
#' @importFrom graphics hist
#' @importFrom robustbase adjbox
#' @export
#' @author Arthur Georges (Post to \url{https://groups.google.com/d/forum/dartr})
#' @examples
#' gl.report.callrate(testset.gl)


gl.report.callrate <- function(x, method="loc", boxplot="adjusted", range=1.5, silent=TRUE, verbose=2) {
  
# TIDY UP FILE SPECS

  build ='Jacob'
  funname <- match.call()[[1]]
  # Note: This function will update Callrate if the flag is FALSE

# FLAG SCRIPT START
  
  if (verbose < 0 | verbose > 5){
    cat("  Warning: Parameter 'verbose' must be an integer between 0 [silent] and 5 [full report], set to 2\n")
    verbose <- 2
  }
  
    cat("Starting",funname,"[ Build =",build,"]\n")

# STANDARD ERROR CHECKING

  if(class(x)!="genlight") {
    stop("Fatal Error: genlight object required!\n")
  }
  
    if (all(x@ploidy == 1)){
      cat("  Processing Presence/Absence (SilicoDArT) data\n")
    } else if (all(x@ploidy == 2)){
      cat("  Processing a SNP dataset\n")
    } else {
      stop("Fatal Error: Ploidy must be universally 1 (fragment P/A data) or 2 (SNP data)!\n")
    }

  # Check for monomorphic loci

  if (!x@other$loc.metrics.flags$monomorphs) {
      cat("  Warning: genlight object contains monomorphic loci which will be factored into Callrate calculations\n")
  }

# DO THE JOB

# RECALCULATE THE CALL RATE, IF NOT PREVIOUSLY DONE
  
  if (!x@other$loc.metrics.flags$monomorphs){
      x <- utils.recalc.callrate(x, verbose=1)
  }  

########### FOR METHOD BASED ON LOCUS    
  
  if(method == "loc") {
    
    callrate <- x@other$loc.metrics$CallRate
    
    # Prepare for plotting
    # Save the prior settings for mfrow, oma, mai and pty, and reassign
    op <- par(mfrow = c(2, 1), oma=c(1,1,1,1), mai=c(0.5,0.5,0.5,0.5),pty="m")
    # Set margins for first plot
    par(mai=c(1,0.5,0.5,0.5))
    # Plot Box-Whisker plot
    if (all(x@ploidy==2)){
      title <- paste0("SNP data (DArTSeq)\nCall Rate by Locus")
    } else {
      title <- paste0("Fragment P/A data (SilicoDArT)\nCall Rate by Locus")
    }  
    if (boxplot == "standard"){
      boxplot(callrate, horizontal=TRUE, col='red', range=range, main = title)
      cat("  Standard boxplot, no adjustment for skewness\n")
    } else {
      robustbase::adjbox(callrate,
                        horizontal = TRUE,
                        col='red',
                        range=range,
                        main = title)
      cat("  Boxplot adjusted to account for skewness\n")
    }  
    # Set margins for second plot
    par(mai=c(0.5,0.5,0,0.5))
    hist(callrate, 
         main="", 
         xlab="", 
         border="blue", 
         col="red",
         xlim=c(min(x@other$loc.metrics$CallRate),1),
         breaks=100)

  # Print out some statistics
    cat("  Reporting Call Rate by Locus\n")
    cat("  No. of loci =", nLoc(x), "\n")
    cat("  No. of individuals =", nInd(x), "\n")
    cat("    Miniumum Call Rate: ",round(min(x@other$loc.metrics$CallRate),2),"\n")
    cat("    Maximum Call Rate: ",round(max(x@other$loc.metrics$CallRate),2),"\n")
    cat("    Average Call Rate: ",round(mean(x@other$loc.metrics$CallRate),3),"\n")
    cat("    Missing Rate Overall: ",round(sum(is.na(as.matrix(x)))/(nLoc(x)*nInd(x)),2),"\n")

  # Determine the loss of loci for a given filter cut-off
    retained <- array(NA,21)
    pc.retained <- array(NA,21)
    filtered <- array(NA,21)
    pc.filtered <- array(NA,21)
    percentile <- array(NA,21)
    for (index in 1:21) {
      i <- (index-1)*5
      percentile[index] <- i/100
      retained[index] <- length(callrate[callrate>=percentile[index]])
      pc.retained[index] <- round(retained[index]*100/nLoc(x),1)
      filtered[index] <- nLoc(x) - retained[index]
      pc.filtered[index] <- 100 - pc.retained[index]
    }
    df <- cbind(percentile,retained,pc.retained,filtered,pc.filtered)
    df <- data.frame(df)
    colnames(df) <- c("Threshold", "Retained", "Percent", "Filtered", "Percent")
    df <- df[order(-df$Threshold),]
    rownames(df) <- NULL
  }
  
########### FOR METHOD BASED ON INDIVIDUAL   
    
  if(method == "ind") {
    
    # Calculate the call rate by individual
    ind.call.rate <- 1 - rowSums(is.na(as.matrix(x)))/nLoc(x)

    # Prepare for plotting
    # Save the prior settings for mfrow, oma, mai and pty, and reassign
    op <- par(mfrow = c(2, 1), oma=c(1,1,1,1), mai=c(0.5,0.5,0.5,0.5),pty="m")
    # Set margins for first plot
    par(mai=c(1,0.5,0.5,0.5))
    # Plot Box-Whisker plot
    if (all(x@ploidy==2)){
      title <- paste0("SNP data (DArTSeq)\nCall Rate by Individual")
    } else {
      title <- paste0("Fragment P/A data (SilicoDArT)\nCall Rate by Individual")
    }  
    if (boxplot == "standard"){
      boxplot(ind.call.rate, 
              horizontal=TRUE, 
              col='red', 
              range=range, 
              ylim=c(min(ind.call.rate),1),
              main = title)
      cat("  Standard boxplot, no adjustment for skewness\n")
    } else {
      robustbase::adjbox(ind.call.rate,
                         horizontal = TRUE,
                         col='red',
                         range=range,
                         ylim=c(min(ind.call.rate),1),
                         main = title)
      cat("  Boxplot adjusted to account for skewness\n")
    }  
    # Set margins for second plot
    par(mai=c(0.5,0.5,0,0.5))
    hist(ind.call.rate, 
         main="", 
         xlab="", 
         col="red",
         xlim=c(min(ind.call.rate),1),
         breaks=100)

    cat("  Reporting Call Rate by Individual\n")
    cat("  No. of loci =", nLoc(x), "\n")
    cat("  No. of individuals =", nInd(x), "\n")
    cat("    Miniumum Call Rate: ",round(min(ind.call.rate),2),"\n")
    cat("    Maximum Call Rate: ",round(max(ind.call.rate),2),"\n")
    cat("    Average Call Rate: ",round(mean(ind.call.rate),3),"\n")
    cat("    Missing Rate Overall: ",round(sum(is.na(as.matrix(x)))/(nLoc(x)*nInd(x)),2),"\n\n")

    # Determine the loss of individuals for a given filter cut-off
    retained <- array(NA,21)
    pc.retained <- array(NA,21)
    filtered <- array(NA,21)
    pc.filtered <- array(NA,21)
    percentile <- array(NA,21)
    crate <- ind.call.rate
    for (index in 1:21) {
      i <- (index-1)*5
      percentile[index] <- i/100
      retained[index] <- length(crate[crate>=percentile[index]])
      pc.retained[index] <- round(retained[index]*100/nInd(x),1)
      filtered[index] <- nInd(x) - retained[index]
      pc.filtered[index] <- 100 - pc.retained[index]
    }
    df <- cbind(percentile,retained,pc.retained,filtered,pc.filtered)
    df <- data.frame(df)
    colnames(df) <- c("Threshold", "Retained", "Percent", "Filtered", "Percent")
    df <- df[order(-df$Threshold),]
    rownames(df) <- NULL
  }

    # Reset the par options    
    par(op) 
    
 # FLAG SCRIPT END
    
    if (verbose > 0) {
      cat("Completed:",funname,"\n")
    }
    
    if(silent==TRUE){
      return(NULL)
    } else{
      return(df)
    } 

}
