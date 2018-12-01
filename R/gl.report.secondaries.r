#' Report loci containing secondary SNPs in a genlight \{adegenet\} object 
#'
#' SNP datasets generated by DArT include fragments with more than one SNP (that is, with secondaries) and record them separately with the same CloneID (=AlleleID).
#' These multiple SNP loci within a fragment are likely to be linked, and so you may wish to remove secondaries.
#' This script reports duplicate loci.
#'
#' @param gl -- name of the genlight object containing the SNP data [required]
#' @return 1
#' @export
#' @author Arthur Georges (Post to \url{https://groups.google.com/d/forum/dartr})
#' @examples
#' gl.report.secondaries(testset.gl)


gl.report.secondaries <- function(gl) {
x <- gl
  
  if(class(x) == "genlight") {
    cat("Reporting for a genlight object\n")
  } else {
    cat("Fatal Error: Specify a genlight or a genind object\n")
    stop()
  }

# Extract the clone ID number
  a <- strsplit(as.character(x@other$loc.metrics$AlleleID),"\\|")
  b <- unlist(a)[ c(TRUE,FALSE,FALSE) ]
# Identify secondaries in the genlight object
  cat("Total number of SNP loci:",nLoc(x),"\n")
  if (is.na(table(duplicated(b))[2])) {
    cat("   Number of secondaries: 0 \n")
  } else {
    cat("   Number of secondaries:",table(duplicated(b))[2],"\n")
  }  
  cat("   Number of loci after secondaries removed:",table(duplicated(b))[1],"\n")

    return(1)
  
}  




