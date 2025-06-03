#procedure:
#1. download everything in bulk_download_files on server
#2. unzip everything (unzip '*.zip')
#3. delete or move all zip archives (rm *.zip)
#4. run this script to generate hydroshare files
#5. upload those files, making sure they are registered as new versions of previously uploaded files


library(tidyverse)
# remotes::install_github("EDIorg/EMLassemblyline")
library(EMLassemblyline)
library(glue)
library(EDIutils)

wd <- '/home/mike/git/streampulse/dataset_build/bulk_download_files'
md <- '../metadata'

setwd(wd)
dir.create(md)

#these lines only need to be run once. template files are then manually edited.
# template_table_attributes(md, wd, 'all_basic_site_data.csv')
template_table_attributes(md, wd, 'all_daily_model_results.csv')


