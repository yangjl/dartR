% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gl2genepop.r
\name{gl2genepop}
\alias{gl2genepop}
\title{Converts a genlight object into genepop format (and file)}
\usage{
gl2genepop(x, outfile = "genepop.gen", outpath = tempdir(), verbose = NULL)
}
\arguments{
\item{x}{Name of the genlight object containing the SNP data [required].}

\item{outfile}{File name of the output file [default 'genepop.gen'].}

\item{outpath}{Path where to save the output file. Use outpath=getwd() or
outpath='.' when calling this function to direct output files to your working
 directory [default tempdir(), mandated by CRAN].}

\item{verbose}{Verbosity: 0, silent or fatal errors; 1, begin and end; 2,
progress log; 3, progress and results summary; 5, full report
[default 2, unless specified using gl.set.verbosity].}
}
\value{
Invisible data frame in genepop format
}
\description{
The genepop format is used by several external applications (for example
Neestimator2
(\url{http://www.molecularfisherieslaboratory.com.au/neestimator-software/}).
So the main idea is to create the genepop file and then run the other
software externally. As a feature, the genepop file is also returned as an
invisible data.frame by the function.
}
\examples{
\dontrun{
# SNP data
geno <- gl2genepop(testset.gl[1:3,1:9])
head(geno)
}
}
\author{
Custodian: Bernd Gruber (Post to
\url{https://groups.google.com/d/forum/dartr})
}
