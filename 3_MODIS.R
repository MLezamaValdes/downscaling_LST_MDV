#' Get and process MODIS LST Swath files
#' 
#' @description 
#' First, MODIS tries to read the qualitycheck.csv file from the getprocessLandsat() function. If it doesn't only contain 
#' the information, that "no data suitable" or "no available data for time range", the day of the month that was being downloaded
#' for is being extracted. 
#' For those days, "MODIS_MOD11_L2_V6" and "MODIS_MYD11_L2_V6" products are queried, and check the queries' tile's overlap with the aoi.
#' Only tiles that have at least 10% area intersection with the aoi will be downloaded and hdfs put into one folder together.
#' The MODIS Swath file is batch tranlated via the HEG tool and collected in one folder.
#' The LST files are being read into R and values converted to valid range (7500-65535) and a scale factor = 0.02 applied. 
#' Data was also converted from K to °C by subtracting 273.15. Tiles are projected  to EPSG 3031 WGS 84 / Antarctic Polar Stereographic.
#' Find a common extent for all files and resample to a clean 1x1km resolution. All MODIS files are being mosaiced. 
#' Find the  max bounding box, bring them all to this resolution and then stack the files and crop to aoi extent. 
#' Next, 4 date rasters are being created, which inform on the amount of available datapoints for each pixel, the minimum and maximum 
#' time and time range covered (time_rasters_MDV_time_range.tif)
#' Then, the goodness of fit between the acquisition time of Landsat 8 and MODIS is calculated by retrieving the L8_date_MDV_timerange.csv
#' file. The L8 time is converted to minute of day and the time difference is being calculated. 
#' @param time_range
#' @return -
#' @author Maite Lezama Valdes
#' @examples
#' year <- c(2019:2013)
#' month <- c("01","02", "12")
#' day <- c(17:22)
#' time_range <- lapply(seq(year), function(j){
#'   lapply(seq(month), function(i){
#'       y <- paste(paste0(year[j],"-",month[i],"-",day), 
#'       paste0(year[j],"-",month[i],"-",day))
#'       strsplit(y, " ")
#'       })
#' })
#' for(y in seq(year)){
#' for(m in seq(month)){
#'   getprocessMODIS(time_range)
#'   }
#' }

getprocessMODIS <- function(time_range, new_download=FALSE){
  
  ####### LOAD PACKAGES, SET PATHS ###############################################################################
  
  # match MODIS downlaod time to available L8 data
  L8scenepath <- paste0(main, "L8/", substring(time_range[[y]][[m]][[1]][[1]], 1, 7), "/")
  # 
  # try(qualL8 <- read.csv(list.files(L8scenepath, pattern="quality", full.names=T)),
  #     silent=T)
  #if(!qualL8[1,] == "no data suitable" && !qualL8[1,]=="no available data for time range"){


  L8scenepath <- paste0(main, "L8/", substring(time_range[[y]][[m]][[1]][[1]], 1, 7), "/")
  try(msel <- readRDS(paste0(L8scenepath, "MODquerymatched_msel.rds")),
      silent=T)
  
  if(exists("msel")){

  msel$msel <- readRDS(paste0(L8scenepath, "MODquerymatched_msel.rds"))
  wgsproj <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
  username = "Mlezama"
  password = "Eos300dm"


  if(any(msel!="nothing")){    
  
  if(length(msel$msel)!=0){
    
  # if there is something useful in L8 data
  #if(exists("qualL8")){
    
  try(timediff_comp <- read.csv2(list.files(L8scenepath, pattern="timediff_df.csv", full.names=T)),silent=T)
  
  if(exists("timediff_comp")){
    


  # cs <- strsplit(as.character(downloadedday$summary), ",", fixed = TRUE)
  # ad <- lapply(cs, `[[`, 2)
  # daynum <- as.numeric(lapply(strsplit(as.character(lapply(strsplit(as.character(ad), ":"),`[[`, 2)), "-"), `[[`, 1))

  L8datetime <- as.POSIXlt(timediff_comp$l8date)
    
    
    print("STARTING MODIS DOWNLOAD AND PREP")
    
    modisscenepath <- paste0(modispath, substring(time_range[[y]][[m]][[1]][[1]], 1, 7), "/")
    oldmodisscenepath <- paste0("E:/new_downscaling/data_download_preprocessing/MODIS/", substring(time_range[[y]][[m]][[1]][[1]], 1, 7), "/")
    hdfpath <- paste0(modisscenepath, "hdfs/")
    MODtifHDFoutpath <- paste0(modisscenepath, "translated/")
    MODLSTpath <- paste0(modisscenepath, "LST/")
    
    
    ## set archive directory
    set_archive(hdfpath)
    
    ## set aoi and time range for the query
    set_aoi(aoiutm)
    
    wgsproj <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"

    aoiwgs <- spTransform(aoi, wgsproj)
    
    query <- msel$msel
    
    print("basic settings done")
    
    
####### GET DATA ONLINE ##############################################################################################
    # if(new_download==TRUE){
    #   
    # 
    #   # get year and doy from query
    #   lapply(seq(query), function(i){
    #     seq(query[[i]], function(j){
    #     ydoy  <- substring(query[[i]][[j]]$summary, 22,28)
    #     yearn <- substring(ydoy, 1,4)
    #     doyn <- substring(ydoy, 5,7)
    #     filenamen <- query[[i]][[j]]$record_id
    #     
    #     url = paste0("https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/6/MOD11_L2/",yearn, "/", doyn, "/", filenamen)
    #     
    #     for(i in seq(url)){
    #       q <- httr::GET(url[i],
    #                      httr::authenticate(username, password) , silent = F)
    #       bin <- httr::content(q, "raw")
    #       writeBin(bin, paste0(modisscenepath, filenamen[i]))
    #       
    #     }
    #     print(paste0("downloaded", query[[i]]$summary))
    #     })
    # 
    #   })
    # }
        
    lapply(seq(query), function(i){
      lapply(seq(query[[i]]), function(j){
        if(!is.null(query[[i]][[j]])){
        if(nrow(query[[i]][[j]]) > 0){
          print(paste0("~~~~~~~~~~ i_j = ", i, "_", j, "~~~~~~~~~~~~", query[[i]][[j]]$record_id, "~~~~~~~~~~"))
          get_data(query[[i]][[j]])
          }
        }
      })
    })
    
    ####### COPY hdfs ##############################################################################################
    
    dlf <- list.files(hdfpath, pattern=".hdf", recursive=T, full.names = T)
    dlf <- dlf[grepl("_datasets", dlf)]
    file.copy(from=dlf,to=paste0(hdfpath, basename(dlf)), overwrite = T)
    
    folder_datasets <- list.files(paste0(hdfpath,"_datasets", "/"), recursive = T, pattern=".hdf$", full.names = T)
    file.remove(folder_datasets)
    
    
    #     # put all hdfs into one folder (hdfpath)
    # if(downloaded_already == TRUE){
    #   
    #   
    #   # check, which of the scenes in the oldmodisscenedirectory are in the timediff_comp file, were queried again
    #   oldmodisscene_in_query <- unlist(lapply(seq(list.files(oldmodisscenepath, pattern=".hdf$", full.names = T)), function(i){
    #     any(grepl(
    #               gsub(substring(list.files(oldmodisscenepath, pattern=".hdf$", full.names = F), 1,26), replacement = ".", pattern="_" )[i],
    #               gsub(timediff_comp$MODname, replacement = ".", pattern="_")
    #         ))
    #   }))
    #   
    #   nl <- paste0(hdfpath, basename(list.files(oldmodisscenepath, pattern=".hdf$")))[oldmodisscene_in_query]
    #   fc <- list.files(oldmodisscenepath, pattern=".hdf$", full.names = T)[oldmodisscene_in_query]
    #   file.copy(from=fc, to=nl,
    #             overwrite = TRUE)
    # } else {
    #   nl <- paste0(hdfpath, basename(list.files(modisscenepath, pattern=".hdf")))
    #   file.copy(from=list.files(modisscenepath, pattern=".hdf$", full.names = T), to=nl,
    #             overwrite = TRUE)
    # }


        print("MODIS data downloaded and in place")

        if(length(list.files(hdfpath, pattern=".hdf$"))!=0){


# ######### BATCH TRANSLATING SWATH TO GEOTIFF WITH HEG TOOL ####################################################
# 
#           # get template prm file
#           tpl <- read.delim(list.files(batchoutdir, pattern="unix.prm", full.names = T),
#                             sep="=", col.names = c("nam", "val"), header = F, stringsAsFactors = F)
# 
#           # run HEG tool to tranlate swaths to geotiff
#           tplpath <- list.files(batchoutdir, pattern="unix.prm", full.names = T)
# 
#           # list all files in hdf dir
#           filescomp <- list.files(hdfpath, full.names=T, pattern="MOD")
# 
#           # clean out batchoutdir if something there from previous run
#           a <- character(0)
#           if(!identical(a, list.files(batchoutdir, pattern=".tif"))){
#             file.remove(list.files(batchoutdir, pattern=".tif", full.names = T))
#           }
# 
#           # run HEG tool
#           try(runheg(files=filescomp, indir=batchindir, outdir=batchoutdir, tplpath=tplpath, layer = "LST|"))
# 
#           # transport results to other filespath
#           dir.create(file.path(MODtifHDFoutpath)) # create MODtifHDFoutpath
#           MODtiffiles <- list.files(batchoutdir, pattern=".tif$", full.names=T)
#           MODtifHEG <- paste0(MODtifHDFoutpath, basename(MODtiffiles))
#           file.copy(from=MODtiffiles, to=MODtifHEG,
#                     overwrite = TRUE)
# 
#           print("batch translating hdf to tif done")


############ GDALWARP TO GEOTIFF ##########################################################################################

          f <- list.files(hdfpath, pattern="hdf$", full.names = T)
          rel_sds <- c("LST", "Error_LST") # relevant subdatasets
          
          dir.create(MODLSTpath)
          lapply(seq(f), function(i){
            
            sds <- get_subdatasets(f[i])
            rel_sds_pos <- c(which(grepl(":LST", sds)), which(grepl(":Error_LST", sds)))
                        # use gdalwarp
            for(j in seq(rel_sds)){
              
              namsds <- strsplit(sds[rel_sds_pos[j]], ":")
              namsdsi <- namsds[[1]][length(namsds[[1]])]
              
              gdalwarp(sds[rel_sds_pos[j]], 
                       dstfile = paste0(MODLSTpath,"warp_", namsdsi,"_", tools::file_path_sans_ext(basename(f[i])), ".tif"),
                       tps=T, # Force use of thin plate spline transformer based on available GCPs.
                       verbose=TRUE,
                       s_srs = wgsproj,
                       t_srs = wgsproj,
                       overwrite = T,
                       tr = c(0.0441,0.0096), # target resolution to match 1000x1000m 
                       te = c(158.5, -78.9, 164.7, -76.0), # crop to rough extent of aoi
                       r="near") # nearest neighbour resampling
            }
            
          })

  
          
######## GO ON PROCESSING LST IN R ########################################################################################

          # get tif files
          lst <- stack(list.files(MODLSTpath, pattern="^warp_LST", full.names=T))
          err <- stack(list.files(MODLSTpath, pattern="^warp_Error", full.names=T))

          print("prepping and writing LST error")
          
          # conversion of error 
          errcnv <- err*0.04
          errc <- crop(errcnv, aoiwgs)
          errcm <- mask(errc, aoiwgs)
          err_proj <- projectRaster(errcm, crs = antaproj)
          writeRaster(err_proj, paste0(MODLSTpath, "proj_", names(err), ".tif"), format="GTiff",
                      overwrite=T,  bylayer=T)
          
          
          # mask by aoi, convert values to valid range and degree C
          print("converting LST DN to valid range and degree Celsius")
          
          lstc <- crop(lst,aoiwgs)
          lstcm <- mask(lstc, aoiwgs)
          
          # Valid Range = 7500-65535
          lstcm[lstcm == 0 ] <- NA
          lstcm[lstcm < 7500 & lstcm > 65535] <- NA
          
          # scale factor = 0.02
          lst_1_conv <- lstcm*0.02
          
          # convert to degree C
          lstc <- lst_1_conv - 273.15
          #spplot(lstc)
        
          # project rasters
          print("projecting rasters - will take quite a while")
          lst_proj <- projectRaster(lstc, crs = antaproj)
          writeRaster(lst_proj, paste0(MODLSTpath, "proj_c_", names(lst), ".tif"), format="GTiff",
                      overwrite=T,  bylayer=T)


          rm(lstc)
          gc()


          print("indidvidual MODIS images stacked and cut to aoi")
          
          # remove stuff that is not needed any more
          lstrm <- list.files(MODLSTpath, pattern="^warp_LST", full.names=T)
          errrm <- list.files(MODLSTpath, pattern="^warp_Error", full.names=T)
          
          file.remove(lstrm, errrm)

          # ################ MAKE DATE RASTERS #################################
          # 
          # #lst_s <- stack(list.files(MODLSTpath, pattern="small", full.names=T))
          # 
          # fnams <- sapply(seq(lst), function(i){
          #   names(lst[[i]])
          # })
          # 
          # utcdates <- lapply(seq(fnams), function(i) {
          #   fnam <- fnams[i]
          #   # get UTC date from fnam
          #   su <- strsplit(fnam, "A")
          #   su <- su[[1]][length(su[[1]])]
          #   org <- paste0(substring(su, 1,4), "-01-01")
          #   utcday <- as.Date((as.numeric(substring(su, 5,7))-1), origin=org)
          # 
          #   if(grepl("v", su)){
          #     utctime <- NULL
          #     utcdate <- utcday
          #   } else {
          #     utctime <- paste0(substring(su, 9, 10), ":", substring(su, 11, 12))
          #     utcdate <- strptime(paste0(utcday,utctime), format='%Y-%m-%d %H:%M', tz="UTC")
          #   }
          #   print(i)
          #   return(utcdate)
          # })
          # 
          # # test
          # v <- NULL
          # for(i in seq(utcdates)){
          #   v[i] <- as.character(utcdates[[i]])
          # }
          # 
          # namdate <- data.frame(fnams=fnams, utc = v)
          # 
          # 
          # # MODdate contains dayofyear, minutesofday as data and as rasters as well
          # MODdate <- datestodoymod(utcdates, fnams, lst_s)
          # 
          # print("MODIS time done")
          # 
          # ############# GOODNESS OF FIT OF ACQUISITION TIME (L8 / MODIS) ##############################
          # 
          # # timeex <- data.frame(extract(tstack, extent(tstack)))
          # 
          # 
          # L8time <- read.csv(paste0(L8datpath, "L8_date_", areaname, time_range[[y]][[m]][[1]][1], ".csv"))
          # L8date <- lapply(seq(nrow(L8time)), function(i){
          #   strptime(paste(L8time$date[i], L8time$time[i]), format='%Y-%m-%d %H:%M:%S', tz="UTC")
          # })
          # 
          # # convert L8 time to minute of day
          # fnamsL8 <- list.files(paste0(L8scenepath, "bt/"), pattern="BTC")
          # 
          # 
          # #L8dates <- datestodoymod(L8date, fnamsL8, lst_s)
          # doy <- sapply(seq(L8date), function(i){
          #   strftime(L8date[[i]], format = "%j")
          # })
          # 
          # minutes <- sapply(seq(L8date), function(i){
          #   minute(L8date[[i]])
          # })
          # 
          # hours <- sapply(seq(L8date), function(i){
          #   hour(L8date[[i]])
          # })
          # 
          # 
          # # make L8 date df
          # minutesofday <- (hours*60)+minutes
          # L8datedf <- L8time
          # 
          # #L8datedf$fnam <- fnamsL8
          # L8datedf$doy <- doy
          # L8datedf$min <- minutes
          # L8datedf$hrs <- hours
          # L8datedf$minday <- minutesofday
          # 
          # # make MODIS date df
          # moddate <- character()
          # for(i in seq(utcdates)){
          #   moddate[i] <- as.character( utcdates[[i]][1])
          # }
          # 
          # modL8datedf <- data.frame(doy=MODdate$dayofyear, minday=MODdate$minutesofday, date=moddate, fnam=fnams)
          # 
          # dir.create(paste0(main, "timediff/", substring(time_range[[y]][[m]][[1]][[1]], 1, 7), "/"))
          # 
          # write.csv2(L8datedf, paste0(main, "timediff/", substring(time_range[[y]][[m]][[1]][[1]], 1, 7), "/", "dates_L8.csv"))
          # write.csv2(modL8datedf, paste0(main, "timediff/", substring(time_range[[y]][[m]][[1]][[1]], 1, 7), "/", "dates_MODIS.csv"))
          # 
          # 
          # 
          # print("timedifference to L8 written")
        } 

      }else {
    print("time differences too big")
  }

  } 

         } else {print("no temporally matching scenes")

          #file.rename(L8scenepath, paste0(substring(L8scenepath, 1, (nchar(L8scenepath)-nchar(basename(L8scenepath))-1)),
          #                                paste0("no_tmatch_",basename(L8scenepath))))
          } # for if there are MODIS scenes within <2h of L8
    }

    gc()
    
} # function




