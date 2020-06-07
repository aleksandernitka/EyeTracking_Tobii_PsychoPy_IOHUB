getpk = function(packages){
    
    for (i in 1:length(packages)){
        if(! packages[i] %in% installed.packages()){
            install.packages(packages[i], dependencies = TRUE)
        }
        sapply(packages[i], require, character.only = TRUE)
    }
}
