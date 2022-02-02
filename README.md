# Labjack_Camera_Trigger
MATLAB functions for generating TTL pulse sequences via a USB DAQ device.

As written, will interface with an attached LabJack U3-LV to produce precisely TTL pulses capable of triggering CMOS cameras (e.g. Mightex BTE-BO50-U). Allows the user to specify complex TTL sequences. 

## Versions
Multiple versions of this code are provided. 
- V1 runs on MATLAB R2017b and earlier.   
- V2 runs on MATLAB R2018a and later. The difference has to do with changes in .NET support in MATLAB R2018a.  
- V3 automatically detects the MATLAB version number, and deploys the correct LabJack commands. Users should use this version for maximum flexibility.  
- ValveBank_LabJackTrigger interfaces with a ValveBank device, and uses TTL pulses from the ValveBank to initiate recordings.

## Installation Notes
If this code has errors, and you're trying to get it on a new computer, make sure the MATLAB SDK add-on is loaded, that the computer has a compiler and .NET libraries (if the computer comes loaded with Microsoft Visual Studio you may already have them) and that the LabJack drivers have been loaded and you've run the LJControlPanel software. Even after all of that, you may have to bang around trying a bunch of things before it works. Start with trying to run the command ljud_LoadDriver and ljud_Constants.  

### Useful Links  
- [Download LabJack Software Installers](https://labjack.com/support/software/installers/ud)
- [Download Mightex Camera Demo Software](https://www.mightexsystems.com/camera-download/)
- [Download Microsoft Visual Studio for latest .NET framework] (https://visualstudio.microsoft.com/)
- [Alternative to Visual Studio: Download Microsoft .NET Framework](https://www.microsoft.com/en-us/download/developer-tools.aspx)
- [Alternative to Visual Studio: Download MinGW C/C++ Compiler](https://www.mathworks.com/matlabcentral/fileexchange/52848-matlab-support-for-mingw-w64-c-c-compiler)
