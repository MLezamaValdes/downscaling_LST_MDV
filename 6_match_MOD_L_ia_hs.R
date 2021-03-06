



########## put allstacks + hs + ia together ############


# per satstack



match_sat_ia_hs <- function(yearmonthsatpath){
  rm(satstack)
  # get satellite stack and rename correctly
  satstack <- stack(yearmonthsatpath)
  
  
  ym <- substring(basename(yearmonthsatpath), 6,12)
  nf <- list.files(paste0(cddir, "satstacks_ngb"), pattern=paste0(ym, ".csv"), full.names = T)
  nf <- nf[grepl("satnames", nf)]
  
  namdat <- read.csv2(nf)
  names(satstack) <- namdat$x
  
  
  timediff_comp_comp <- read.csv2(list.files(paste0(cddir, "comp_comp_files"), pattern=ym, full.names = T))
  
  uniqueMODscenes <- unique(timediff_comp_comp$modscene)
  
  # get naming of ia and hs
  dateaschar <- lapply(seq(uniqueMODscenes), function(i){
    MD <- substring(uniqueMODscenes[i],11,22)
    MODDate <- as.POSIXct(MD, tz="UTC",format = "%Y%j_%H%M")
    paste0(substring(as.character(MODDate),1,10), "-", substring(as.character(MODDate),12,13),
           "_", substring(as.character(MODDate),15,16))
  })
  
  
  
  
  # read resampled and stacked ia and hs
  iahs_files_month <- list.files(iahsrespath, full.names=T, pattern=ym)
  iahs <- c("ia", "hs")
  
  ia_hs <- lapply(seq(iahs_files_month), function(i){
    x <- stack(iahs_files_month[[i]])
    names(x) <- paste0(iahs,substring(names(x),6,26))
    return(x)
  })
  
  iahsf <- sans_ext(basename(iahs_files_month))
  ia_hs_nam <- substring(iahsf,11)
  
  iahsm <- stack(ia_hs)
  
  # get MODIS names from satstack
  lo <- seq(1,(length(names(satstack))-1),by=2) # lo=Landsat
  hi <- lo+1 # hi=MODIS
  
  modsatnam <- names(satstack[[hi]])
  
  # get naming of ia and hs from MODIS scenes in stack
  dateascharstack <- lapply(seq(modsatnam), function(i){
    if(grepl("small", modsatnam[i])){
      MD <- substring(modsatnam[i],22,33)
      MODDate <- as.POSIXct(MD, tz="UTC",format = "%Y%j.%H%M")
      paste0(substring(as.character(MODDate),1,10), "-", substring(as.character(MODDate),12,13),substring(as.character(MODDate),15,16))
    } else {
      MD <- substring(modsatnam[i],11,22)
      MODDate <- as.POSIXct(MD, tz="UTC",format = "%Y%j.%H%M")
      paste0(substring(as.character(MODDate),1,10), "_", substring(as.character(MODDate),12,13),
             "_",substring(as.character(MODDate),15,16))
    }
  })
  
  datemod <- unlist(dateascharstack)
  
  pos <- sapply(seq(datemod), function(i){ # find positions matching 
    grep(datemod[i], ia_hs_nam)
  })
  
  # merge stacks
  satiahs_stack <- lapply(seq(modsatnam), function(i){
    if(length(pos[[i]])>0){
      print(i)
      stack(satstack[[lo[i]]], satstack[[hi[i]]], ia_hs[[pos[[i]]]])
    }
  })
  
  tf <- sapply(seq(satiahs_stack), function(i){
    length(satiahs_stack[[i]]) > 0
  })
  
  tempdyn <- stack(satiahs_stack[tf])
  
  
  write.csv2(names(tempdyn), paste0(cddir, "satstacks_ngb/names_sat_ia_hs_", ym, ".csv"),
             row.names = F)
  
  print("starting to write complete satellite stack")
  writeRaster(tempdyn, paste0(cddir, "satstacks_ngb/L_MOD_hs_ia_", ym, ".tif"),
              overwrite=T)
    
  } 
  





