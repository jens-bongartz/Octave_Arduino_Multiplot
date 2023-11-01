# Octave Arduino Multiplot
Octave_Arduino_Multiplot is an Octave Script that receives data from the the serial interface of the computer and processes and visualizes these data. The data are usually provided by an Arduino microcontroller - hence the name of the project.

### Definition of datasets and their elements
The data is transmitted as plain ASCII text (strings), which makes it easy readable with a monitor programs. The current transmission speed is 115.200 baud (but can be changed).
Datasets are encoded in lines of text terminated with CR\LF (or \r\n), as is the case with Arduino's serial.println() command.

To have a consistent terminology the following definition is used:

Each element of a dataset is a name-value pair (https://en.wikipedia.org/wiki/Name-value_pair) separated by a colon (name:value): 

e.g. "EKG:234"

Different elements of a dataset are seperated by a comma: 

"EKG:234,t:5"

As mentioned a dataset is terminated by CR\LF (or \r\n):  

"EKG:234,t:5\r\nEKG:345,t:6\r\nEKG:987,t:7\r\n"

CR\LF (or \r\n) is not visible but printed as a new line. It looks like this in a monitor program: 

EKG:234,t:5

EKG:345,t:6

EKG:987,t:7
