tobii.cleaner = function(CSVFilesPath, filterByLocation, screenSize = c(1920,1080), samplingHz ) {
    
    # This function should take path to a folder where CSV files pre-processed with the tobii.extractor are stored
    # function should allow for the following:
    # Create Averages of x and y gaze as well as x,y and z eye positions
    # Filter data based on tracker code
    # Filter data based on location
    
    
    #/*
    #* ----------------------------------------------------------------------------
    #* "THE BEER-WARE LICENSE" (Revision 42):
    #* <aleksander.nitka@nottingham.ac.uk> 
    #* wrote this file. As long as you retain this notice you
    #* can do whatever you want with this stuff. If we meet some day, and you think
    #* this stuff is worth it, you can buy me a beer in return. Aleksander W. Nitka
    #* ----------------------------------------------------------------------------
    #*/
    
    # IOHUB Tobii data captured
    # http://www.isolver-solutions.com/iohubdocs/iohub/api_and_manual/device_details/eyetracker_interface/Tobii_Implementation_Notes.html
    
    
    #CSVFilesPath = ''
    
    setwd(CSVFilesPath)
    csvFilesList = list.files(CSVFilesPath, pattern = "\\.csv$")
    
    if (length(hdfFilesList) == 0){
        
        return(message('No CSV files found in the directory provided.'))
    }
    
    
    for (f in 1:length(csvFilesList)) {
        
        message(sprintf("Extracting file %i / %i - %s", f, length(csvFilesList), csvFilesList[f]))
     
        # Load file to a df
        df = read.csv(csvFilesList[f], header = TRUE)
        
        # Record lost samples
        df$trackLoss = FALSE
        
        # Create l/r averages for x,y for gaze as well as eyes x,y,z and pupil measures
        
        df$gaze_x = (df$left_gaze_x + df$right_gaze_x)/2
        df$gaze_y = (df$left_gaze_y + df$right_gaze_y)/2
        df$eyes_x = (df$left_eye_cam_x + right_eye_cam_x)/2
        df$eyes_y = (df$left_eye_cam_y + right_eye_cam_y)/2
        df$eyes_z = (df$left_eye_cam_z + right_eye_cam_z)/2
        df$pupil1 = (left_pupil_measure1 + right_pupil_measure1)/2
        
        # Filter on tracker status code:
        # Both eyes' data missing:
        # Set all to NA
        filterCondStatus = (df$status != 0)
        
        df$gaze_x[filterCondStatus]  = NA
        df$gaze_y[filterCondStatus]  = NA
        df$eyes_x[filterCondStatus]  = NA
        df$eyes_y[filterCondStatus]  = NA
        df$eyes_z[filterCondStatus]  = NA
        df$pupil1[filterCondStatus]  = NA
        df$trackloss[filterCondStatus]  = TRUE

        if (filterByLocation == TRUE) {
            # Filter on impossible values - gaze reported is outside the screen
            filterCondLocation      = (abs(df$gaze_x) > screenSize[1]/2 | abs(df$gaze_y) > screenSize[2]/2 )
            
            df$gaze_x[filterCondLocation]  = NA
            df$gaze_y[filterCondLocation]  = NA
            df$eyes_x[filterCondLocation]  = NA
            df$eyes_y[filterCondLocation]  = NA
            df$eyes_z[filterCondLocation]  = NA
            df$pupil1[filterCondLocation]  = NA
            df$trackloss[filterCondLocation]  = TRUE
        }
        

        # Overwrite old file
        write.csv(df, file = csvFilesList[f])
        
           
    }
}