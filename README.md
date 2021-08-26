# Labjack_Camera_Trigger
MATLAB functions for generating TTL pulse sequences via a USB DAQ device.

As written, will interface with an attached LabJack U3-LV to produce precisely TTL pulses capable of triggering CMOS cameras (e.g. Mightex BTE-BO50-U). Allows the user to specify complex TTL sequences. 

## Versions
Multiple versions of this code are provided. 
V1 runs on MATLAB R2017b and earlier. 
V2 runs on MATLAB R2018a and later. The difference has to do with changes in .NET support in MATLAB R2018a
V3 automatically detects the MATLAB version number, and deploys the correct LabJack commands. Users should use this version for maximum flexibility. 
