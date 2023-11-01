# Octave_Arduino_Multiplot
Octave_Arduino_Multiplot is an Octave Script that receives data from the the serial interface of the computer and processes and visualizes these data. The data are usually provided by an Arduino microcontroller - hence the name of the project.
The data is transmitted as plain ASCII text, which makes it readable with serial monitor programs. The current transmission speed is 115.200 baud (but can be changed).
Datasets are encoded in lines of text terminated with CR\LF (or \r\n), as is the case with Arduino's serial.println() command.
To have a consistent terminology here are a definition of a dataset:

