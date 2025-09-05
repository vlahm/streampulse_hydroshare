# procedure:
# 1. download everything in bulk_download_files on server
## if you just run this on previous years' files, they will get messed up
# 2. unzip everything (unzip '*.zip')
# 3. clean up (rm *.zip)
# 4. run this script to generate hydroshare files***
#     ***in general, commented code need not be rerun. in some cases, rerunning it will cause problems
# 5. upload those files, making sure they are registered as new versions of previously uploaded files

library(tidyverse)
# remotes::install_github("EDIorg/EMLassemblyline")
library(EMLassemblyline)
library(glue)
# library(EDIutils)

wd <- "/home/mike/git/streampulse/dataset_build/bulk_download_files"
md <- "../metadata"
reach_char_dir <- file.path(wd, 'reach_characterization_datasets')

setwd(wd)
dir.create(md)

# uncomment this. only commented for safety during development
# for(f in list.files(wd)){
#     file.rename(f, sub('^all_', '', f))
# }

# these lines only need to be run once. template files are then manually edited.
# template_table_attributes(md, wd, 'basic_site_data.csv')
# template_table_attributes(md, wd, 'daily_model_results.csv')
# template_table_attributes(md, wd, 'grab_data.csv')
# template_table_attributes(md, wd, "model_summary_data.csv")

## simple files ####

read_csv("grab_data.csv") %>%
    mutate(
        unit = case_match(
            variable,
            "TOC" ~ "ppm",
            "TN" ~ "ppm",
            "TP" ~ "ppm",
            "TDN" ~ "mg/L",
            "TDP" ~ "mg/L",
            "SRP" ~ "mg/L",
            "DOC" ~ "ppm",
            "DIC" ~ "ppm",
            "TSS" ~ "ppm",
            "fDOM" ~ "ppb",
            "Carbon dioxide" ~ "ppm",
            "CO2" ~ "ppm",
            "Methane" ~ "ug/L",
            "CH4" ~ "ug/L",
            "Nitrous oxide" ~ "ug/L",
            "N2O" ~ "ug/L",
            "DO" ~ "mg/L",
            "DO Sat" ~ "%",
            "DO_Sat" ~ "%",
            "Chlorophyll-a" ~ "mg/L",
            "Chl-a" ~ "mg/L",
            "Alkalinity" ~ "meq/L",
            "pH" ~ "pH units",
            "Spec Cond" ~ "mS/cm",
            "Spec_Cond" ~ "mS/cm",
            "Turbidity" ~ "NTU",
            "Light Atten." ~ "1/m",
            "Light_Atten" ~ "1/m",
            "Illuminance" ~ "lux",
            "PAR" ~ "W/m^2",
            "UV Absorbance" ~ "1/cm",
            "UV_Absorbance" ~ "1/cm",
            "Canopy Cover" ~ "LAI",
            "Canopy_Cover" ~ "LAI",
            "Width" ~ "m",
            "Depth" ~ "m",
            "Distance" ~ "m",
            "Discharge" ~ "m^3/s",
            "k" ~ "1/min",
            "Water Temp" ~ "C",
            "Water_Temp" ~ "C",
            "Air Temp" ~ "C",
            "Air_Temp" ~ "C",
            "Water Pres" ~ "kPa",
            "Water_Pres" ~ "kPa",
            "Air Pres" ~ "kPa",
            "Air_Pres" ~ "kPa"
        ),
        unit = if_else(is.na(unit), "mole", unit)
    ) %>%
    relocate("unit", .after = "value") %>%
    write_csv("grab_data.csv")

read_csv("model_summary_data.csv") %>%
    select(-any_of(c(
        'requested_variables',
        'year',
        'engine',
        'used_rating_curve',
        'GPP_95CI',
        'ER_95CI',
        'current_best'
    ))) %>%
    write_csv("model_summary_data.csv")

## streampulse input data ####

sp_data <- purrr::map_dfr(
    list.files(pattern = "^sp_data"),
    read_csv
)

dir.create("inputdata_streampulse", showWarnings = FALSE)

for (region in unique(sp_data$regionID)) {
    warning('still removing PR_QS depth and discharge')
    sp_data %>%
        filter(regionID == !!region) %>%
        #temp
        filter(! (regionID == 'PR' & siteID == 'QS' & variable %in% c('Depth_m', 'Discharge_m3s'))) %>%
        ###
        arrange(siteID, dateTimeUTC) %>%
        write_csv(glue(
            "inputdata_streampulse/inputdata_streampulse_region",
            region,
            ".csv"
        ))
}

# template_table_attributes(md, file.path(wd, 'inputdata_streampulse'),
#                           'inputdata_streampulse_regionNC.csv')

## neon input data ####

neon_data <- purrr::map_dfr(list.files(pattern = '^neon'), read_csv)

dir.create("inputdata_neon", showWarnings = FALSE)

neon_sites <- unique(neon_data$siteID)
neon_sites <- unique(str_match(neon_sites, '.*(?=\\-(?:down|up))'))
for (site in neon_sites) {
    neon_data %>%
        filter(grepl(!!site, siteID)) %>%
        arrange(dateTimeUTC) %>%
        write_csv(glue(
            "inputdata_neon/inputdata_neon_site",
            site,
            ".csv"
        ))
}

## reach characterization data ####

for (f in list.files(reach_char_dir)) {
    ff <- file.path(reach_char_dir, f)
    read_lines(ff)[-1] %>%
        write_lines(ff)
}


## then, to generalize filenames, run something like
#    rename  s/_WI// attributes_WI_synoptic*
#    rename  s/_WI/_reachchar/ attributes_WI_*

## model objects (and remove predictions objects) ####

# gg = readRDS('sp_model_objects/modOut_AL_MAYF-up_2018.rds')
# ff = readRDS('sp_model_objects/predictions_AL_MAYF-up_2018.rds')
# write_csv(ff, '/tmp/predictions.csv')
# zz = readRDS('/media/mike/USB20FD/example_sm_output.rds')

# dir.create('predictions')
preds_files <- list.files(
    'sp_model_objects/',
    pattern = '^predictions',
    full.names = F
)
for (f in preds_files) {
    file.remove(file.path('sp_model_objects', f))
    # file.rename(file.path('sp_model_objects', f),
    #             file.path('predictions', f))
}

# template_table_attributes(md, '/tmp/', 'predictions.csv')

## cleanup ####

file.remove("../metadata/custom_units.txt")

# for(f in list.files(md)){
#     if(grepl('model_objects', f)) next
#     oldname <- file.path(md, f)
#     newname <- sub('\\.txt$', '.csv', oldname)
#     file.rename(oldname, newname)
#     file.rename(newname, sub('^attributes', 'metadata', newname))
# }

read_csv('daily_model_results.csv') %>%
    rename(regionID = region, siteID = site, datetime = date) %>%
    write_csv('daily_model_results.csv')

read_csv('model_summary_data.csv') %>%
    rename(regionID = region, siteID = site) %>%
    write_csv('model_summary_data.csv')

read_csv('grab_data.csv') %>%
    rename(datetime = dateTimeUTC) %>%
    write_csv('grab_data.csv')

# for(f in list.files('inputdata_streampulse', full.names = TRUE)){
#     read_csv(f) %>%
#         rename(datetime = dateTimeUTC) %>%
#     write_csv(f)
# }

#this zipping approach probably won't work on windows.
system('zip -r9 inputdata_streampulse.zip inputdata_streampulse')
system(
    'zip -r9 reach_characterization_datasets.zip reach_characterization_datasets'
)
system('zip -r9 sp_model_objects.zip sp_model_objects')
system('zip -r9 supplementary_site_metadata.zip supplementary_site_metadata')
setwd('..')
system('zip -r9 metadata.zip metadata')
