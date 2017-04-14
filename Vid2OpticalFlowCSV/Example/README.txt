Vid2OpticalFlowCSV Usage Example
--------------------------------

IMPORTANT NOTE: The executable Vid2OpticalFlowCSV.exe was built with OpenCV 2.4.9 (DLL). 
				In order to run this executable, you'll need this exact version of OpenCV and 
				also add OpenCV's bin directory to your path. Otherwise, you can compile Vid2OpticalFlowCSV 
				locally with whatever OpenCV version.


This directory contains an example for the Vid2OpticalFlowCSV utility. 
The utility reads a video sequence and estimates the optical flow in a grid of WxH blocks, and writes the result to a CSV file, 
which can be used by other software to analyse motion patterns in the video.

USAGE:

   Vid2OpticalFlowCSV.exe  [-l <string>] [-d <string>] [-c <string>] [-o <string>] -v <string> [--] [--version] [-h]


Where:

   -l <string>,  --lens <string>
     Lens Correction Param File

   -d <string>,  --dump <string>
     Dump Directory

   -c <string>,  --config <string>
     Config File

   -o <string>,  --out <string>
     Output CSV File

   -v <string>,  --video <string>
     (required)  Input Video File

   --,  --ignore_rest
     Ignores the rest of the labeled arguments following this flag.

   --version
     Displays version information and exits.

   -h,  --help
     Displays usage information and exits.




Example 1: Produce CSV only
----------------------------
Produce an output CSV file using the default config provided with this tool:

Vid2OpticalFlowCSV.exe -v sample_vid.mp4 -c ..\default-config.xml -o sample_vid.csv

This will create am output CSV file called 'sample_vid.csv'.


Example 2: Produce CSV + Frame dumps
--------------------------------------
Produce an output CSV file using the default config provided with this tool and dump each frame into a separate PNG file.

Vid2OpticalFlowCSV.exe -v sample_vid.mp4 -c ..\default-config.xml -o sample_vid.csv -d framesdumpdir

This will create a CSV file called 'sample_vid.csv' and a subdir named 'framesdumpdir' with a PNG file per frame.



Example 3: Fix lens distortion + Produce CSV + Frame dumps
----------------------------------------------------------
Fix lens distortion using pre-determined lens parameters, estimate optical flow, dump result to CSV file and dump each lens-corrected frame into a separate PNG file. 
The file 'hero3-und-params.txt' contains the lens parameters of 'GoPro Hero 3' and 'hero3_plus_und-params.txt' contains the lens parameteres of 'GoPro Hero 3+'.

Vid2OpticalFlowCSV.exe -v sample_vid.mp4 -c ..\default-config.xml -o sample_vid.csv -d framesdumpdir  -l ..\hero3_plus_und-params.txt

This will create a CSV file called 'sample_vid.csv' and a subdir named 'framesdumpdir' with a PNG file per frame.



