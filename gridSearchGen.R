#---- SETUP ----
  #work directory
  wdPath = dirname(rstudioapi::getActiveDocumentContext()$path)
  setwd(wdPath)
  
  
#---- PARAMETER INPUT ----
  #name and path to file
  fileName = paste0(wdPath, "/gridSearchParameters.CSV")
  
  #node names and values
  nodes    = list("/Data/Blocks/TURB-1/Input/PRES" = seq(90, 200, length.out = 5),
                  "/Data/Blocks/TURB-2/Input/PRES" = seq(2, 30, length.out = 5))
  
  #output names
  output   = c("/Data/Flowsheeting Options/Calculator/EFFCALC/Output/WRITE_VAL/6")

  
#---- Generate File ----  
  #compute combination of values
  nodeVals     = do.call(expand.grid, nodes)
  
  #generate empty status vector and output matrices 
  combNumber   = nrow(nodeVals)
  status       = rep(-1, combNumber)
  outputMatrix = matrix(0, combNumber, length(output),
                        dimnames = list(1:combNumber, output))
  
  #combine all into single data frame
  gridMatrix   = cbind(nodeVals, status, outputMatrix)
  
  #save as CSV
  write.csv(gridMatrix, file = fileName)
  View(gridMatrix)
  