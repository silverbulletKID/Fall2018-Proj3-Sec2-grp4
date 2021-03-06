#########################################################
### Train a classification model with training features ###
#########################################################

### Author: Chengliang Tang
### Project 3


train <- function(dat_train, label_train, par=NULL){
  
  ### Train a Gradient Boosting Model (GBM) using processed features from training images
  
  ### Input: 
  ###  -  features from LR images 
  ###  -  responses from HR images
  ### Output: a list for trained models
  
  ### load libraries
  library("gbm")
  
  ### creat model list
  # modelList <- list()
  
  ### Train with gradient boosting model
  if(is.null(par)){
    depth <- 3
  } else {
    depth <- par$depth
  }
  
  ### the dimension of response arrat is * x 4 x 3, which requires 12 classifiers
  ### this part can be parallelized
  modelList = foreach (i = 1:12,.export = c("gbm.fit","gbm.perf") ) %dopar% {
    ## calculate column and channel
    c1 <- (i-1) %% 4 + 1
    c2 <- (i-c1) %/% 4 + 1
    featMat <- dat_train[, , c2]
    labMat <- label_train[, c1, c2]
    fit_gbm <- gbm.fit(x=featMat, y=labMat,
                       n.trees=200,
                       shrinkage = 0.1,
                       distribution="gaussian",
                       interaction.depth=depth, 
                       bag.fraction = 0.5,
                       verbose=FALSE)
    best_iter <- gbm.perf(fit_gbm, method="OOB", plot.it = FALSE)
    list(fit=fit_gbm, iter=best_iter)
  }
  
  ### restart cluster to release memory
  if(.Platform$OS.type=="windows"){
    stopImplicitCluster()
    stopCluster(cl)
    cl <- makeCluster(cores)
    registerDoParallel(cl, cores=cores)
  }
  return(modelList)
}
