#' Recursively collapse a distance matrix by amalgamating populations
#'
#' This script generates a fixed difference matrix from a genlight object \{adegenet\} and from it generates a population recode
#' table used to amalgamate populations with a fixed difference count less than or equal to a specified tpop. 
#' The script then repeats the process until there is no further amalgamation of populations.
#' 
#' The distance matricies are generated by gl.fixed.diff(), a recode table is generated using gl.collapse() and the resultant
#' recode table is applied to the genlight object using gl.recode.pop(). The process is repeated as many times as necessary to
#' yield a final table with no fixed differences less than or equal to the specified threshold, tpop. 
#' The intermediate and final recode tables and distance matricies are stored to disk as csv files for use with other analyses. 
#' In particular, the recode tables can be edited to replace populaton labels with meaninful names and reapplied in sequence.
#'
#' @param gl -- name of the genlight object from which the distance matricies are to be calculated [required]
#' @param prefix -- a string to be used as a prefix in generating the matricies of fixed differences (stored to disk) and the recode
#' tables (also stored to disk) [default "collapse"]
#' @param tloc -- threshold defining a fixed difference (e.g. 0.05 implies 95:5 vs 5:95 is fixed) [default 0]
#' @param tpop -- max number of fixed differences allowed in amalgamating populations [default 0]
#' @param v -- verbosity = 0, silent; 1, brief; 2, verbose [default 1]
#' @return A new genlight object with recoded populations after amalgamations are complete.
#' @import reshape2
#' @export
#' @author Arthur Georges (glbugs@aerg.canberra.edu.au)
#' @examples
#' fd <- gl.collapse.recursive(testset.gl, prefix="testset",tloc=0,tpop=2)

gl.collapse.recursive <- function(gl, prefix="collapse", tloc=0, tpop=2, v=1) {
  
# Set the iteration counter
  count <- 1
  
# Create the initial distance matrix
  if (v==2) {cat("Calculating an initial fixed difference matrix\n")}
  fd <- gl.fixed.diff(gl, tloc=tloc, v=v)
  
# Store the length of the fd matrix
  fd.hold <- dim(fd)[1]
  
# Construct a filename for the fd matrix
  d.name <- paste0(prefix,"_matrix_",count,".csv")
  
# Output the fd matrix for the first iteration to file
  if (v==2) {cat(paste("     Writing the initial fixed difference matrix to disk:",d.name,"\n"))}
  write.csv(fd, d.name)

# Repeat until no change to the fixed difference matrix
  if( v==2 ){
    cat("Collapsing the initial fixed difference matrix iteratively until no further change\n")
    if( tpop == 0) {
      cat("     Collapsing on zero fixed differences only\n")
    } else {  
      cat(paste("     Collapsing populations with =",tpop,"or fewer fixed differences\n"))
    }  
  } 
  
  repeat {
    if( v==2 ){cat(paste("\nITERATION ", count,"\n"))}
    
    # Construct a filename for the pop.recode table
      recode.name <- paste0(prefix,"_recode_",count,".csv")
      
    # Collapse the matrix, write the new pop.recode table to file
      gl <- gl.collapse(fd, gl, recode.table=recode.name, tpop=tpop, v=v)
      
    #  calculate the fixed difference matrix fd
      fd <- gl.fixed.diff(gl, tloc=tloc, pc=FALSE, v=v)
      
    # If it is not different in dimensions from previous, break
      if (dim(fd)[1] == fd.hold) {
        cat(paste("\nNo further amalgamation of populations at fd <= ",tpop,"\n"))
        break
      }
      
    # Otherwise, construct a filename for the collapsed fd matrix
      d.name <- paste0(prefix,"_matrix_",count+1,".csv")
      
    # Output the collapsed fixed difference matrix for this iteration to file
      if( v==2 ){cat(paste("Writing the collapsed fixed difference matrix to disk:",d.name,"\n"))}
      write.csv(fd, d.name)
      
    # Hold the dimensions of the new fixed difference matrix, increment iteration counter
      fd.hold <- dim(fd)[1]
      count <- count + 1
  }
  
  if (v > 0) {
    if (tloc == 0 ){
      cat("Using absolute fixed differences\n")
    } else {  
      cat("using fixed differences defined for each locus with tolerance",tloc,"\n")
    }   
    cat("Number of fixed differences allowing population amalgamation fd <=",tpop,"(",round((tpop*100/nLoc(gl)),4),"%)\n")
    cat("Resultant recode tables and fd matricies output with prefix",prefix,"\n")
    cat("NOTE: Lower matrix, percent fixed differences; upper matrix, no. of loci\n")
  }
  
  return(gl)
}
