tobii.dwellCalculator = function(csvFilesPath, temporalWindow, AOI1, AOI2, AOI3, AOI4) {
    
    # csvFilesPath - where the files live
    # temporalWindow - 
    # AOIx - four values specifying left border, right border, top and bottom in px
    
    
    setwd(CSVFilesPath)
    csvFilesList = list.files(CSVFilesPath, pattern = "\\.csv$")
    
    # Check inputs
    if (length(hdfFilesList) == 0){
        
        return(message('No CSV files found in the directory provided.'))
    }
    
    if (length(AOI1) == 0 | length(AOI2) == 0 | length(AOI3) == 0 | length(AOI4) == 0 ){
        return(message('Please specify at least one AIO'))
    }
    
    if (length(temporalWindow) != 0) {
        if (length(temporalWindow) == 1){
            return(message('Please specify start and end, too few values provided.'))
        }
        else if (length(temporalWindow) > 2){
            return(message('Please specify start and end, too many values provided.'))
        }
        else {
            start = temporalWindow[1]
            stop = temporalWindow[2]
            
            if (stop<start){
                return(message(sprintf('Temporal window invalid; start t: %i is smaller than stop t: %i', start, stop)))
            }
        }
        
    } 
    
    # Process files   
    
    for (f in 1:length(csvFilesList)) {
        
        message(sprintf("Processing file %i / %i - %s", f, length(csvFilesList), csvFilesList[f]))
        
        # Load file to a df
        df = read.csv(csvFilesList[f], header = TRUE)
        
        # init dwell values
        taoi1 = 0
        taoi2 = 0
        taoi3 = 0
        taoi4 = 0
        
        for (trial in 0:max(df$trialNo)) {
            
            # subset trial
            t = subset(df, df$trialNo == trial)
            
            # subset if temporal window applied
            if (lenght(temporalWindow) != 0) {
                t = t[start:stop]
                if (nrow(t) < 5){
                    message(sprintf('Subset of a trial too short with $i samples',nrow(t)))
                }
            }
            
            for (sample in 1:nrow(t)){
                # AOI1
                if (t$gaze_x[sample] >= AOI1[1] & t$gaze_x[sample] <= AOI1[2] & t$gaze_y[sample] >= AOI1[3] & t$gaze_x[sample] <= AOI1[4] ){
                    taoi1 = taoi1+1
                }
                # AOI2
                if (t$gaze_x[sample] >= AOI2[1] & t$gaze_x[sample] <= AOI2[2] & t$gaze_y[sample] >= AOI2[3] & t$gaze_x[sample] <= AOI2[4] ){
                    taoi2 = taoi2+1
                }
                # AOI3
                if (t$gaze_x[sample] >= AOI3[1] & t$gaze_x[sample] <= AOI3[2] & t$gaze_y[sample] >= AOI3[3] & t$gaze_x[sample] <= AOI3[4] ){
                    taoi3 = taoi3+1
                }
                # AOI4
                if (t$gaze_x[sample] >= AOI4[1] & t$gaze_x[sample] <= AOI4[2] & t$gaze_y[sample] >= AOI4[3] & t$gaze_x[sample] <= AOI4[4] ){
                    taoi4 = taoi4+1
                }
                
                tmp = c(t$trialNo[sample], taoi1, taoi2, taoi3, taoi4)
            }
            
            
            
        }
        
        # Export a new file called ssX_dwell with trial ID, condition, dwell A-D
    }
}