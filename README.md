# How to use iohub data store with PsychoPy (Eye Tracking data)

IOHUB offers a quick and reliable solution to high frequency data storage. Here, I show how to: (a) by using only few lines of added code create a working relationship between the IOHUB store and the PsychoPy and (b) how to extract this data to a csv file for further processing. 

## PsychoPy
The PsychoPy code used here is an adaptation from '[Python for eye-tracking workshop](http://www.psychopy.org/resources/ECEM_Python_materials.zip)' (ECEM, August 2013 by Sol Simpson, Michael MacAskill and Jon Peirce).

Before we start adding any extra code blocks you need to add a new field called `Eye Tracker` to the `Experiment Info` in `Experimental Settings`. If you leave the default blank the tracking will not be initiated, you can enable/disable tracking on each experiment by entering any value/leaving blank this field when you run your experiment. 

Now, once you have added `Eye Tracker` you will need to add a few blocks of extra code. Add a `Code` block and into the **Begin Experiment** part enter: 

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
Please note that the above code uses a hardware configuration file `tobii_std.yaml` which is specific to your tobii device. An example Tobii TX300 `tobii_std.yaml` file is included in this repo.

We also need some code to be exectuted in the **End Experiment** part:

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

Now, the actual tracking part. The below code will start the tracker (and send an appropriate message to the IOHUB) at the beggining of the routine and end tracking when the routine ends. The below code assumes that you have one tracking period per trial. Add a new code element into trial routine and in `Begin Routine` add:

```python
if expInfo['Eye Tracker']:
    io.clearEvents('all')
    eyetracker.setRecordingState(True)
    io.sendMessageEvent(text="tStart %i %i" %(trials.thisN, Condition))
```
The `io.sendMessageEvent(text="tStart %i %i" %(trials.thisN, Condition))` sends a message to the IOHUB which will record trial number and condition for that trial, the `Condition` has to refer to a name in your design which specifies the condition.

Then in the **End Routine** for the same code block add:

```python
if expInfo['Eye Tracker']:
    eyetracker.setRecordingState(False)
    io.sendMessageEvent(text="tEnd %i" %(trials.thisN, Condition))
```

Upon completion of the experiment you should see a new hdf5 file being added to the root directory this will be named 'hdf5_et_X_YYYY.hdf5' where X is your participant's id and YYYY is a date and time. If instead you see the 'events.hdf5' file then this means that either you have not included the **End Experiment** code or the experiment was termined before it run was meant to finish. 

Note, that using the `io.sendMessageEvent(text="Some Text")` you can send any other information that you may find useful such as condition, stimuli names etc. Here, I wanted to focus on core functionality and the attached R script will only extract the trial number from the 

## Example Experiment
The `etDemo.psyexp` is a simple experiment in which people are asked to look at the dots, it has been designed with PsychoPy 1.82.01 (Mac).

## Processing the HDF5 file
Thanks to the codes we were sending to the IOHUB on each trials we are able to epoch the eyetracking data based on realted time vales. To process the data you need to have R installed on your machine, and have some very basicc knowledge of R, you should know how to open an R script file, execture the code and then input one line of code into the R's console. 

All the R function needs is the location of hdf5 files; it will get all the trials epoched and save output into a csv file. The output file may be quite big as it collects all trails for each participant; if your tracker is sampling at 300Hz that means that you can expect around 300 lines per second of tracking. 

The output data is a raw and unfiltered output which can be filtered by trail number. You can also use the trial number to get all other trial info that has not been passed to IOHUB 
