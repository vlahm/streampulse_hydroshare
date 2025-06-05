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
# library(EDIutils)

wd <- '/home/mike/git/streampulse/dataset_build/bulk_download_files'
md <- '../metadata'

setwd(wd)
dir.create(md)

#uncomment this. only commented for safety during development
# for(f in list.files(wd)){
#     file.rename(f, sub('^all_', '', f))
# }

file.remove('model_input_summary_data.csv') #not worth including

#these lines only need to be run once. template files are then manually edited.
# template_table_attributes(md, wd, 'basic_site_data.csv')
# template_table_attributes(md, wd, 'daily_model_results.csv')
# template_table_attributes(md, wd, 'grab_data.csv')
template_table_attributes(md, wd, 'model_summary_data.csv')

read_csv('grab_data.csv') %>% 
    mutate(
        unit = case_match(
            variable,
            'TOC' ~ 'ppm',
            'TN' ~ 'ppm',
            'TP' ~ 'ppm',
            'TDN' ~ 'mg/L',
            'TDP' ~ 'mg/L',
            'SRP' ~ 'mg/L',
            'DOC' ~ 'ppm',
            'DIC' ~ 'ppm',
            'TSS' ~ 'ppm',
            'fDOM' ~ 'ppb',
            'Carbon dioxide' ~ 'ppm',
            'CO2' ~ 'ppm',
            'Methane' ~ 'ug/L',
            'CH4' ~ 'ug/L',
            'Nitrous oxide' ~ 'ug/L',
            'N2O' ~ 'ug/L',
            'DO' ~ 'mg/L',
            'DO Sat' ~ '%',
            'DO_Sat' ~ '%',
            'Chlorophyll-a' ~ 'mg/L',
            'Chl-a' ~ 'mg/L',
            'Alkalinity' ~ 'meq/L',
            'pH' ~ 'pH units',
            'Spec Cond' ~ 'mS/cm',
            'Spec_Cond' ~ 'mS/cm',
            'Turbidity' ~ 'NTU',
            'Light Atten.' ~ '1/m',
            'Light_Atten' ~ '1/m',
            'Illuminance' ~ 'lux',
            'PAR' ~ 'W/m^2',
            'UV Absorbance' ~ '1/cm',
            'UV_Absorbance' ~ '1/cm',
            'Canopy Cover' ~ 'LAI',
            'Canopy_Cover' ~ 'LAI',
            'Width' ~ 'm',
            'Depth' ~ 'm',
            'Distance' ~ 'm',
            'Discharge' ~ 'm^3/s',
            'k' ~ '1/min',
            'Water Temp' ~ 'C',
            'Water_Temp' ~ 'C',
            'Air Temp' ~ 'C',
            'Air_Temp' ~ 'C',
            'Water Pres' ~ 'kPa',
            'Water_Pres' ~ 'kPa',
            'Air Pres' ~ 'kPa',
            'Air_Pres' ~ 'kPa'
        ),
        unit = if_else(is.na(unit), 'mole', unit)
    ) %>% 
    relocate('unit', .after = 'value') %>% 
    write_csv('grab_data.csv')

read_csv('model_summary_data.csv') %>% 
    select(-requested_variables, -year, -engine, -used_rating_curve,
           -GPP_95CI, -ER_95CI, -current_best) %>% 
    write_csv('model_summary_data.csv')

neon_data <- purrr::map_dfr(list.files(pattern = '^neon'),
                            read_csv)
neon_data <- 

file.remove('../metadata/custom_units.txt')