tobii.extractor = function(hdf5FilesPath, extract = 'all', saveRdata = FALSE) {
    
    source('getpk.R', local = TRUE) # auto install and load packages
    
    getpk(c('hdf5r'))
    
    setwd(hdf5FilesPath)
    
    hdfFilesList = list.files(pattern = "\\.hdf5$")
    
    if (length(hdfFilesList) == 0){
        
        return(message('No HDF5 files found in the directory provided.'))
    }
    
    # Progress
    pb = txtProgressBar(min = 0, max = length(hdfFilesList), initial = 0, style = 3) 
    
    for (f in 1:length(hdfFilesList)) {
        
        df = H5File$new(hdfFilesList[f], mode="r")
        # import eyetracker events
        et = df[["data_collection/events/eyetracker/BinocularEyeSampleEvent"]]
        et = et[] 
        # import experiment evnts
        ex = df[["data_collection/events/experiment/MessageEvent"]]
        ex = ex[]
        
        # Get subejct id from Events
        ssid = sapply(strsplit(grep('SSID: ', ex$text, value = TRUE), split = ": "), "[", 2)
        # try to extract ssid from other names, but quit if not found an id
        if (length(ssid) == 0){
            ssid = sapply(strsplit(grep('SUBJECT ID: ', ex$text, value = TRUE), split = ": "), "[", 2)

            if (length(ssid) == 0){
                ssid = sapply(strsplit(grep('SUBJECT: ', ex$text, value = TRUE), split = ": "), "[", 2)

                if (length(ssid) == 0){
                    message(sprintf('Error. Could not extract ssid from the file %s', hdfFilesList[f]))
                    stopifnot(length(ssid)>0)
                }

            }
        }
        # add leading 0 to ssid if 1:9
        if (nchar(ssid) == 1){
            ssid = paste('0', ssid, sep = '')
        }
        
        # Prepare Events, keep only start/end messages
        # phrases = c('tStart ', 'tEnd ')
        phrases = c('ts ', 'te ')
        ex = subset(ex, grepl(paste(phrases, collapse = "|"), ex$text))
        
        # Create start/end references
        ex$tStart = NA
        ex$tEnd = NA
        ex$tDur = NA
        
        # Trial number extraction 
        ex$tNo = NA
        et$tNo = NA
        et$Condition = NA
        
        # Space for subject id
        et$ssID = NA
        
        
        for (l in 1:nrow(ex)) {
            
            # tne below two lines will only work if those variables we need are at a specified location after
            # the string is split by space. One may need to adjust this to work with their code
            ex$tNo[l] = as.numeric(strsplit(ex$text[l], split = ' ')[[1]][3])
            ex$Condition[l] = strsplit(ex$text[l], split = ' ')[[1]][4]
            
            if ((grepl('ts ', ex$text[l])) == TRUE) {
                ex$tStart[l] = ex$time[l]
                ex$Condition[] = ex$Condition[l+1]
                
                if ((grepl('te ', ex$text[l+1])) == TRUE){
                    ex$tEnd[l] = ex$time[l+1]
                }
                
                else {
                    message(sprintf('trial start/end structure not valid: %s', hdfFilesList[f]))
                }
            }
            
            ex$tDur[l] = ex$tEnd[l] - ex$tStart[l]
            
        }
        
        # Remove all 'trial end' messages
        ex = subset(ex, grepl('ts ',ex$text))
        
        
        for(i in 1:nrow(ex)) {
            
            filt = et$time >= ex$tStart[i] & et$time <= ex$tEnd[i]
            
            et$tNo[filt] = ex$tNo[i]
            et$Condition[filt] = ex$Condition[i]
            et$ssID[filt] = ssid
            
            
        }
        
        if (extract == 'all'){
            # nothing to do
        } else if (extract == 'trials'){
            et = subset(et, is.na(et$tNo) == FALSE)
        }
        
        if (saveRdata == TRUE){
            assign(sprintf("ss%s_tobiiData", ssid), et, envir = .GlobalEnv)
            assign(sprintf("ss%s_eventsData", ssid), ex, envir = .GlobalEnv)
        }
        
        # Save file
        write.csv(et, file = sprintf("ss%s_tobiiData.csv", ssid), row.names = FALSE)
        write.csv(ex, file = sprintf("ss%s_eventsData.csv", ssid), row.names = FALSE)
        
        # Progress
        setTxtProgressBar(pb,f)
        
    }
    
}