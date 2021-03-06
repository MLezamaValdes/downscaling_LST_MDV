########## tune final models ###############################


print("loading Palma libs and paths")


n <- 150000


loc="Palma"
if(loc=="Palma"){
  
  outpath <- "/scratch/tmp/llezamav/modeling_after_talk/"
  trainpath <- "/scratch/tmp/llezamav/train_valid/"
  modelpath <- outpath
  
  

  library(CAST,lib.loc="/home/l/llezamav/R/")
  library(caret,lib.loc="/home/l/llezamav/R/")
  library(gbm,lib.loc="/home/l/llezamav/R/")
  library(parallel)
  library(doParallel)
  library(kernlab,lib.loc="/home/l/llezamav/R/")
  #testsubset <- read.csv2("/scratch/tmp/llezamav/satstacks/extraction_result_new/test_n2000.csv")
  
  
  print("loading datasets")
  train <- read.csv2(paste0(trainpath, "train_LHS_150000.csv"))
  
  print("loaded train dataset")

}
if(loc=="Laptop"){

  library(parallel)
  library(doParallel)
  library(randomForest)
  library(gbm)
  library(CAST)
  library(caret)
  trainpath <- "D:/downscaling_after_talk/clean_data/train_valid/"
   modelpath <- "D:/downscaling_after_talk/models/"
   outpath <- modelpath
 
  
  train <- read.csv2(paste0(trainpath, "train_LHS_150000.csv"))

}





print("libraries loaded")


print(paste0("nrow train = ", nrow(train)))

testing=FALSE


# see Hanna's script: 
# https://github.com/HannaMeyer/AntAir/blob/0dcfb14dd93f2c44467e4450be685cca6f9f66b4/AntAir/02_TrainAndPredict/08_finalModel.R


################################################################################
# Settings
################################################################################
seed <- 100
cores <- detectCores()-3

kval <- 3
print(paste("k crossvalidation folds:", kval))

# split training cuarter into various blocks for cv during training
foldids <- CreateSpacetimeFolds(train, spacevar="spatialblocks", timevar = "ymo",
                                k=kval,seed=100)


(trainlength <- sapply(seq(foldids$indexOut), function(i){
  length(foldids$indexOut[[i]])
}))

set.seed(100)

metric <- "RMSE" # Selection of variables made by either Rsquared or RMSE
methods <- c("rf",
             "nnet",
             "gbm")
withinSE <- FALSE # favour models with less variables or not?
response <- train$Landsat
n <- 150000

cl <- makeCluster(cores)
registerDoParallel(cl)
################################################################################
# Train models
################################################################################

for (i in 1:length(methods)){
  
  method <- methods[i]
  print(method)
  tuneLength <- 2
  tuneGrid <- NULL
  
  ffs_model <- get(load(paste0(modelpath, "ffs_model_",method,"_", n, ".RData")))
  print(paste0("model name = ", "ffs_model_",method,"_", n, ".RData"))
  predictornames <- ffs_model$selectedvars
  print(predictornames)
  predictors <- train[,which(names(train)%in%predictornames)]
  print(paste0("amount predictors for ", method, " = ", ncol(predictors)))
  pv <- ncol(predictors)
  
  
  tctrl <- trainControl(method="cv", 
                        savePredictions = TRUE,
                        returnResamp = "all",
                        verboseIter=TRUE,
                        index=foldids$index,
                        indexOut=foldids$indexOut)
  
  #### tuning settings ##############
  
  if (method=="rf"){
    #   tuneLength <- 1
    tuneGrid <-  expand.grid(mtry = c(seq(2,pv,1)))
    
  
    # Create A Data Frame From All Combinations Of Factor Variables, 
    # mtry: Number of variables randomly sampled as2-10 candidates at each split
  }
  if (method=="gbm"){
    tuneGrid <-  expand.grid(interaction.depth = seq(3,14,2), 
                             n.trees = c(100,200,300,400,500),
                             shrinkage = c(0.01,0.05,0.1),
                             n.minobsinnode = 10)
    
    #tuneLength <- 10
    predictors <- data.frame(scale(predictors))
    
    tctrl <- trainControl(method="repeatedcv",
                          number=kval,
                          repeats=kval,
                          savePredictions = TRUE,
                          returnResamp = "all",
                          verboseIter=TRUE,
                          index=foldids$index,
                          indexOut=foldids$indexOut)
    
  }
  if (method=="nnet"){
    #   tuneLength <- 1
    
    predictors <- data.frame(scale(predictors))
    # tuneGrid <- expand.grid(size = seq(2,ncol(predictors),2),
    #                         decay = seq(0,0.1,0.025))
    # 
    # tuneGrid <- expand.grid(size = seq(2,ncol(predictors),1),
    #                         decay = seq(0,0.1,0.01))
    
    tuneGrid <- expand.grid(decay = c(0.5, 0.1, 1e-2, 1e-3, 1e-4, 1e-5, 1e-6, 1e-7),
                size = c(1, 2, 3, 5, 10, 20))
    
    
  }
  
  if (method=="svmLinear"){ # C controls how large the support vectors, i.e. margins are
    #   tuneLength <- 1
    tuneGrid <- expand.grid(C= c(0:16))

  }
  
  
  #### training ##############
  
  
  if(method=="nnet"){ # importance = TRUE kills it
    model_final <- train(predictors,
                         response,
                         method = method,
                         tuneGrid = tuneGrid,
                         trControl = tctrl,
                         trace = FALSE, #relevant for nnet
                         linout = TRUE) # relevant for nnet
  

  }  else if(method=="gbm"){
    
    model_final <- train(predictors,
                         response, 
                         method=method, 
                         trControl=tctrl,
                         tuneGrid=tuneGrid,
                         withinSE = FALSE,
                         tuneLength=tuneLength,           
                         metric=metric)


  } else {
  
    model_final <- train(predictors,
                         response,
                         metric=metric,
                         method = method,
                         importance =TRUE,
                         tuneGrid = tuneGrid,
                         trControl = tctrl,
                         trace = FALSE, #relevant for nnet
                         linout = TRUE)	
  

  }
  
  save(model_final,file=paste0(modelpath,"final_model_",method,"_", n, ".RData"))
}

stopCluster(cl)


