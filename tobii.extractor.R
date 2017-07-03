tobii.extractor = function(hdf5FilesPath) {
    
    # TODO
    # [ ] change code for grepl ssid to what is in psychopy
    # [ ] trial start and end codes as per new psychopy code on github
    # [ ] rm path from this code
     
    if ('rhdf5' %in% installed.packages() == FALSE){
        source("http://bioconductor.org/biocLite.R")
        biocLite("rhdf5")    
    }
    
    require('rhdf5')
    
    hdf5FilesPath = "~/Documents/git/Coder-Eyetracking-IOHUB-Psychopy"
    
    setwd(hdf5FilesPath)
    
    hdfFilesList = list.files(hdf5FilesPath, pattern = "\\.hdf5$")
    
    if (length(hdfFilesList) == 0){
        
        return(message('No HDF5 files found in the directory provided.'))
    }
    
    for (f in 1:length(hdfFilesList)) {
        
        message(sprintf("Extracting file %i / %i - %s", f, length(hdfFilesList), hdfFilesList[f]))
        
        # Extract Events from hdf5
        tmp.events = h5read(hdfFilesList[f], '/data_collection/events/experiment/MessageEvent')
        
        # Extract EyeTracking data from hdf5
        tmp.eyetr  = h5read(hdfFilesList[f], '/data_collection/events/eyetracker/BinocularEyeSampleEvent')
        
        # Get subejct id from Events
        ssid = sapply(strsplit(grep('SSID: ', tmp.events$text, value = TRUE), split = ": "), "[", 2)

        
        # Create DF for trials data
        tmp.df = data.frame(matrix(ncol = ncol(tmp.eyetr)))
        names(tmp.df) = names(tmp.eyetr)
        
        # Prepare Events, keep only start/end messages
        tmp.events = subset(tmp.events, grepl('Trial ',tmp.events$text))
        
        # Create start/end references
        tmp.events$tStart = NA
        tmp.events$tEnd   = NA
        
        # Trial number extraction 
        tmp.events$tNo = NA
        tmp.df$tNo     = NA
        
        # Space for subject id
        tmp.df$ssID    = NA
        
        for (l in 1:nrow(tmp.events)) {
            
            tmp.events$tNo[l] = as.numeric(strsplit(tmp.events$text[l], split = ' ')[[1]][2])
            
            if ((grepl('tStart ', tmp.events$text[l])) == TRUE) {
                tmp.events$tStart[l] = tmp.events$time[l]
                
                if ((grepl('tEnd ', tmp.events$text[l+1])) == TRUE){
                    tmp.events$tEnd[l] = tmp.events$time[l+1]
                }
                
                else {
                    message('trial start/end structure not valid')
                }
            }
            
        }
        
        # Remove all 'trial end' messages
        tmp.events = subset(tmp.events, grepl('tStart ',tmp.events$text))
        
        
        for(e in 1:nrow(tmp.events)) {
            
            # Subset the EyeTracking data based on start/end
            tmp.raw.trial = subset(tmp.eyetr, tmp.eyetr$time >= tmp.events$tStart[e] & tmp.eyetr$time <= tmp.events$tEnd[e])
            
            tmp.raw.trial$tNo = tmp.events$tNo[e]
            
            tmp.raw.trial$ssID = ssid
            
            tmp.df = rbind(tmp.raw.trial, tmp.df)

            
        }
        
        # Add ssid
        tmp.df$ssID = ssid
        
        # Save file
        name = sprintf("ss%s_tobiiData", ssid)
        write.csv(tmp.df, file = paste(name, "csv", sep = '.'))
    
        
    }
    

}
