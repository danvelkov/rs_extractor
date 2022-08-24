
# automatic install of packages if they are not installed already
list.of.packages <- c(
  "vcfR"
)

new.packages <-
  list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]

if (length(new.packages) > 0) {
  install.packages(new.packages, dep = TRUE)
}

# loading packages
for (package.i in list.of.packages) {
  suppressPackageStartupMessages(library(package.i,
                                         character.only = TRUE))
}

#get number of cores for parallel package
n.cores <- parallel::detectCores() - 1

# create the cluster
my.cluster <- parallel::makeCluster(n.cores,
                                    type = "PSOCK")

# register it to be used by %dopar%
doParallel::registerDoParallel(cl = my.cluster)

# !/usr/bin/env Rscript
# optparse options definitions
option_list = list(
  make_option(
    c("-i", "--input"),
    type = "character",
    default = NULL,
    help = "Vcf file containing SNPs",
    metavar = "<file>.vcf"
  ),
  make_option(
    c("-o", "--output"),
    type = "character",
    default = "result.html",
    help = "Output html file visualising chromosome regions",
    metavar = "<file>.html"
  )
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

# check if input file is included
if (is.null(opt$input)) {
  print_help(opt_parser)
  stop("At least one argument must be supplied (input file).n", call. =
         FALSE)
}

# defining file path variables from command call
input_file = opt$input
output_file = opt$output
dir_name = normalizePath(dirname(output_file))


# create output directory if it doesn't exist
if (!dir.exists(dir_name))
  dir.create(dir_name)

# load of vcf file
vcf <-
  read.vcfR(input_file)

records <-
  getFIX(vcf, getINFO = TRUE)

# extracting the annotation data containing id, chr, positions 
# and adding link to existing reference SNPs or clinical significance Clinvar reference
invisible(foreach (row_count = 1:nrow(records), .packages = 'filelock') %dopar% {
  line <- c()
  
  elem_name <- records[row_count, 3]

  line <-
    paste(c(elem_name),
          collapse = "\n")

  # writing to file with simple lock for concurrency
  lck <- lock("/tmp/anno_file.lock")
  write(line,
        anno_file, append = TRUE)
  unlock(lck)
})

#stop cluster
parallel::stopCluster(cl = my.cluster)