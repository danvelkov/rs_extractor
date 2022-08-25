

# automatic install of packages if they are not installed already
list.of.packages <- c("vcfR",
                      "optparse",
                      "doParallel")

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

# list of chromosomes
chromosome = list(1,
                  2,
                  3,
                  4,
                  5,
                  6,
                  7,
                  8,
                  9,
                  10,
                  11,
                  12,
                  13,
                  14,
                  15,
                  16,
                  17,
                  18,
                  19,
                  20,
                  21,
                  22,
                  "X",
                  "Y")


# create output directory if it doesn't exist
if (!dir.exists(paste(dirname(output_file), "/separated_chromosomes", sep="")))
  dir.create(paste(paste(dirname(output_file), "/separated_chromosomes", sep="")))

if (!dir.exists(paste(dirname(output_file),"/chromosome_accessions/", sep="")))
  dir.create(paste(paste(dirname(output_file), "/chromosome_accessions/", sep="")))

chromosome_files_dir <- list()

# separating chromosomes into different files
foreach (chr = 1:length(chromosome)) %do% {
  file_name <- paste(dirname(output_file),
                     "/separated_chromosomes/",
                     basename(output_file), "_chr", chromosome[chr], sep="")
  
  command <- paste(
    "bcftools view ",
    input_file,
    " --regions ",
    chromosome[chr],
    " > ",
    file_name, 
    sep= "")
  
  chromosome_files_dir <- c(chromosome_files_dir, file_name)
  print(command)
  system(command)
}

foreach (file = 1:length(chromosome_files_dir)) %do% {
  print(chromosome_files_dir[file][[1]])
  
  file_name <- paste(dirname(output_file),
                     "/chromosome_accessions/",
                     basename(output_file), "_chr", chromosome[chr], "_accession", sep="")
  
  command <- paste(
    "bcftools query -f '%ID\n'",
    input_file,
    " > ",
    file_name, 
    sep= "")
  system(command)
  
}