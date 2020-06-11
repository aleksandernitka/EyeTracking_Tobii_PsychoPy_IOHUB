# How to use iohub data store with PsychoPy (Eye Tracking data)

<a href="https://zenodo.org/badge/latestdoi/94903132"><img src="https://zenodo.org/badge/94903132.svg" alt="DOI"></a>

IOHUB offers a quick and reliable high frequency data storage. Here, I show how to: (a) by using only few lines of added code create a working relationship between the IOHUB store and the PsychoPy and (b) how to extract this data to a csv file for further processing. 

## PsychoPy
The PsychoPy code used here is an adaptation from '[Python for eye-tracking workshop](http://www.psychopy.org/resources/ECEM_Python_materials.zip)' (ECEM, August 2013 by Sol Simpson, Michael MacAskill and Jon Peirce).

Before you start adding any extra code blocks you need to add a new field called `Eye Tracker` to the `Experiment Info` in `Experimental Settings`. If you leave the default blank the tracking will not be initiated, you can enable/disable tracking on each experiment by entering any value/leaving blank this field when you run your experiment. 

Now, once you have added `Eye Tracker` you will need to add a few blocks of extra code. Add a `Code` block and into the **Begin Experiment** tab enter: 

```python
import os
import shutil

try:
    os.remove('events.hdf5')
except OSError:
    pass

if expInfo['Eye Tracker']:
    try:
        from psychopy.iohub import EventConstants,ioHubConnection,load,Loader
        from psychopy.iohub.util import NumPyRingBuffer
        from psychopy.data import getDateStr
        
        # Load the specified iohub configuration file converting it to a python dict.
        io_config=load(file('tobii_std.yaml','r'), Loader=Loader)
        
        # Add / Update the session code to be unique. Here we use the psychopy getDateStr() function for session code generation
        session_info=io_config.get('data_store').get('session_info')
        session_info.update(code="S_%s"%(getDateStr()))

        # Create an ioHubConnection instance, which starts the ioHubProcess, and informs it of the requested devices and their configurations.
        io=ioHubConnection(io_config)

        iokeyboard=io.devices.keyboard
        mouse=io.devices.mouse
        if io.getDevice('tracker'):
            eyetracker=io.getDevice('tracker')

            win.winHandle.minimize()
            eyetracker.runSetupProcedure()
            win.winHandle.activate()
            win.winHandle.maximize()
            win.flip()

        ## Send some info about the experiment to the IOHUB
        io.sendMessageEvent(text="%s"%(expInfo['expName']))
        io.sendMessageEvent(text="DATE: %s"%(expInfo['date']))
        io.sendMessageEvent(text="SSID: %s"%(expInfo['participant']))


    except Exception, e:
       import sys
       print "!! Error starting ioHub: ",e," Exiting..."
       sys.exit(1)
```
Please note that the above code uses a hardware configuration file `tobii_std.yaml` which is specific to your tobii device. An example Tobii TX300 `tobii_std.yaml` file is included in this repo and should be in the same directory as the PsychoPy file.

We also need some code to be executed in the **End Experiment** part:

```python
if expInfo['Eye Tracker']:
    eyetracker.setConnectionState(False)
    io.sendMessageEvent(text="EXPERIMENT FINISHED")
    io.quit()

    ## Save hdf5 file as a new file
    oldnhdf5 = 'events.hdf5'
    newhdf5 = 'hdf5_et_%s_%s.hdf5' %(expInfo['participant'],expInfo['date'])
    shutil.move(oldnhdf5, newhdf5)
```

Now, the actual tracking part. The below code will start the tracker (and send an appropriate message to the IOHUB) at the begging of a routine and end tracking when a routine ends. The below code assumes that you have one tracking period per trial. Add a new code element into trial routine and in `Begin Routine` add:

```python
if expInfo['Eye Tracker']:
    io.clearEvents('all')
    eyetracker.setRecordingState(True)
    io.sendMessageEvent(text="tStart %i %i" %(trials.thisN, Condition))
```
The `io.sendMessageEvent(text="tStart %i %i" %(trials.thisN, Condition))` sends a message to the IOHUB which will record trial number and condition for that trial, the `Condition` has to refer to a name in your design which specifies the condition. Note, that you can pass any information to the IOHUB using this method. 

**Note:** Make sure, that the `trials.thisN` is unique for each trial across the entire experiment. This may not be the case when you for example use a xlsx file as a design and specify to repeat it more than once. 

Then in the **End Routine** for the same code block add:

```python
if expInfo['Eye Tracker']:
    eyetracker.setRecordingState(False)
    io.sendMessageEvent(text="tEnd %i" %(trials.thisN, Condition))
```

Upon completion of the experiment you should see a new hdf5 file being added to the root directory this will be named `hdf5_et_X_YYYY.hdf5` where X is your participant's id and YYYY is a date and time. If instead you see the `events.hdf5` file in the experiment folder then this means that either you have not included the **End Experiment** code or the experiment was terminated before it run was meant to finish. 

## Example Experiment
The `etDemo.psyexp` is a simple experiment in which subjects are asked to look at the dots, it has been designed with PsychoPy 1.82.01 (Mac).

## Processing the HDF5 file
Thanks to the codes we were sending to the IOHUB on each trial, we are able to epoch the eye tracking data based on related time vales. To process the data you need to have R installed on your machine, and have some very basic knowledge of R. You should know how to open an R script file and execute code. Having [RStudio](https://rstudio.com/) installed would make this process much less painful. 

All the R function needs is the location of hdf5 files; it will get all the trials epoched and save output into a csv file, optionally it will save all required data into your R environment. The output file may be quite big as it collects all trials for each participant; if your tracker is sampling at 300Hz that means that you can expect around 300 lines per second of tracking. 

To process the HDF5 output files make sure that you follow the PsychoPy method described above, then:
* Open a new R script file with [RStudio](https://rstudio.com/ then save it the same location that `tobii.extractor.R` and `getpk.R` files are. The latter file is a small script which automatically checks and downloads required packages. 

* Insert the following into the code editor: 

  ```R
  source('tobii.extractor.R')
  ```

* Then in a separate lane, sepcify the location of files (the folder in which the hdf5 files are): 

  ```R
  dir = '~/path/to/your/HDF5files'
  ```

* In a next line insert: 

  ```R
  tobii.extractor(dir)
  ```

* The extracting function allows us to specify what we can extract from the hdf5 files:

  * To only extract the data recorded during the trials use (if you want all the data, just omit that argument or set it to `'all'`):

    ```R
    tobii.extractor(dir, extract = 'trial')
    ```

  * To save data to your R environment, which would be helpfull if you plan on to work with that data later, use:

    ```R
    tobii.extractor(dir, saveRdata = TRUE)
    ```

  * Both arguments can be stacked:

    ```R
    tobii.extractor(dir, extract = 'trial', saveRdata = TRUE)
    ```

* Execute the entire code. It may take a while to extract all files and it may also take a lot of your disk space.

* For each participant you will get two files, one contains raw eye-tracking data (file name contains string `tobiiData`) and second with all events that has been sent to IOHUB from PsychoPy (contains string `eventsData`). 

* You can subset the csv data isolte tracking data for a particular trial (`tNo` column in the csv).

# 2020 update:

* Decided to move away from bioconductor's [rhdf](https://github.com/grimbough/rhdf5) package to [hdf5r](https://hhoeflin.github.io/hdf5r/) and streamline the hdf5 process. Could not have the time and will to adapt the code so it works with the hdf5 format that psychopy is producing after updating to a new version of the package. 
* Some changes have been made to the code to make it more robust and streamline it so it's slightly easier to understand it, I hope. 



### Dependencies:

hdf5r
