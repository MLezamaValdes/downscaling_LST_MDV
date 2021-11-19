Downscaling Workflow
================
Maite
15 8 2021

# This document

This document summarizes the different steps required for the
downscaling approach described in XXX and links to the scripts within
this repository in the adequate order. The resulting downscaling model
and necessary predictor data to downscale a MODIS scene captured during
the austral summer months during daylight conditions and the McMurdo Dry
Valleys can be installed from [Github repo](https://github.com/MLezamaValdes/downscaleLST.MDV)

## Basic settings

-   load libraries
-   define time range
-   create directories for Landsat and MODIS data to be downloaded
-   read Area of Interest (AOI) shape
-   define and source some functions

## 1 Preparing the Digital Elevation Model (DEM)

``` r
file.edit("1_DEM.R")
```

## 2 Selecting, downloading and processing Landsat Band 10 to Land Surface Temperature (LST)

Scenes that show little cloud contamination, are overlapping the AOI
sufficiently and are temporally closely matching an available MODIS
scene are being selected and queried.

``` r
file.edit(paste0(scriptpath_organized, "2_1_selectLandsat.R"))
file.edit(paste0(scriptpath_organized, "2_2a_downloadLandsat.R"))
file.edit(paste0(scriptpath_organized, "2_2b_downloadLandsat.R"))
file.edit(paste0(scriptpath_organized, "2_2c_place_scenes.R"))
file.edit(paste0(scriptpath_organized, "2_3_processLandsat.R"))
```

## 3 MODIS

MOD11\_L2 and MYD11\_L2 data come already cloud masked by MODIS product
MOD35\_L2.

``` r
file.edit("3_MODIS.R")
```

## 4 Creating a Landsat and MODIS data stack per month

``` r
file.edit("4_make_sat_stack.R")
```

## 5 Create incidence angle and hillshading raster

For each unique MODIS scene capturing time, topographic solar shading
and the solar incidence angle are calculated based on the DEM and the
corresponding solar position.

``` r
file.edit("Palma/5_ia_hs_Palma.R")
```

## 6 Match satellite LST data and solar insolation variables

``` r
file.edit("6_match_MOD_L_ia_hs.R")
```

## 7 extract data from raster stacks to table format

``` r
file.edit("Palma/7_stack_extraction_Palma.R")
```

## 8 Gather training dataset using most dissimilar samples

Gather a training dataset by choosing the most dissimilar samples from
3Mio random samples taken from the training areas and months (10 of 15
months for which data was available during the sampling period from 2013
to 2019). This approach was pursued in order to provide the model with
the best coverage of environmental conditions within the feature space
of predictor and response variable. Afterwards, the amount of samples is
reduced to a manageable sample size of 150000 data points via a
Latin-Hypercube sampling for the training data and a random sampling
from the validation areas and time steps.

``` r
file.edit("Palma/8_DI_log_choosing_Palma_3m.R")
file.edit("Palma/8a_gather_train_LHS_valid_rand.R")
```

## 9 Forward Feature Selection for Random Forest, Gradient Boosting Machine and Neural Net

``` r
file.edit("Palma/9_FFS_remodelling_rf.R")
file.edit("Palma/9_FFS_models_gbm_SE_F.R")
file.edit("Palma/9_FFS_models_nnet_SE_F.R")
```

## 10 Evaluate FFS

``` r
file.edit("10_evaluate_FFS_remodelling.R")
```

## 11 Tune final models

``` r
file.edit("Palma/11_tune_final_models.R")
file.edit("Palma/11_tune_final_models_remod_fast_few_mtry.R")
file.edit("Palma/11_looking_at_final_models.R")
```

## 12 External testing

``` r
file.edit("12_external_testing_remodelling.R")
```
