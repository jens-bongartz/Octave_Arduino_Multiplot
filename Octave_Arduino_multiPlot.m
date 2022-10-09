%
%  Dies ist eine Octave-Skript zur Darstellung von Daten die über die
%  serielle Schnittstelle empfangen werden (z.B. ein EKG-Signal).
%  Die Daten können mit einer Kaskade von digitalen Filtern gefiltert werden.
%
%  (c) Jens Bongartz, September 2022, RheinAhrCampus Remagen
%  Stand: 04.10.2022
%  ==========================================================================
pkg load instrument-control;
clear all;
#
# Serieller Port muss von Hand eingestellt werden
# ===============================================
# Windows
# serialPortPath = "COM3";
# MacOSX
#serialPortPath = "/dev/cu.usbmodem142401";
serialPortPath = "/dev/tty.usbserial-110";
# Linux
#serialPortPath = "/dev/ttyUSB0";
#
#  Konfiguration der Signalauswertung ueber die serielle Schnittstelle
#
dataStream(1).name = "rot";
dataStream(1).array = [ ];
dataStream(1).plot = 1;
dataStream(1).plcolor = "red";
dataStream(1).ylim = 0;
dataStream(1).adc_plot = [ ];
dataStream(1).filter = 1;
dataStream(1).HP01_sp = [0 0 0 0 0 0];                    % Filter-Speicher
dataStream(1).No50_sp = [0 0 0 0 0 0];                    % Filter-Speicher
dataStream(1).TP40_sp = [0 0 0 0 0 0];                    % Filter-Speicher

dataStream(2).name = "ir";
dataStream(2).array = [ ];
dataStream(2).plot = 1;
dataStream(2).plcolor = "blue";
#dataStream(2).ylim = [-20 20];
dataStream(2).ylim = 0;
dataStream(2).adc_plot = [ ];
dataStream(2).filter = 1;
dataStream(2).HP01_sp = [0 0 0 0 0 0];                    % Filter-Speicher
dataStream(2).No50_sp = [0 0 0 0 0 0];                    % Filter-Speicher
dataStream(2).TP40_sp = [0 0 0 0 0 0];                    % Filter-Speicher

dataStream(3).name = "t";
dataStream(3).array = [ ];
dataStream(3).plot = 0;
dataStream(3).plcolor = "green";
dataStream(3).ylim = 0;
dataStream(3).adc_plot = [ ];
dataStream(3).filter = 0;
dataStream(3).HP01_sp = [0 0 0 0 0 0];                    % Filter-Speicher
dataStream(3).No50_sp = [0 0 0 0 0 0];                    % Filter-Speicher
dataStream(3).TP40_sp = [0 0 0 0 0 0];                    % Filter-Speicher

#min_bytesAvailable = 10;
#min_x_index_step = 10;
min_bytesAvailable = 1;
min_x_index_step = 1;
fensterbreite = 200;

# Globale Variablen
global HP01_filtered = 0;
global No50_filtered = 0;
global TP40_filtered = 0;
global quit_prg = 0;
global clear_data = 0;
global save_data = 0;
global rec_data = 1;

x_index =  0;
x_index_prev = 0;

% Initialisiere Plot-Fenster
% ==========================
graphics_toolkit("qt");
fi_1 = figure(1);
clf
spN = 0;
for i = 1:length(dataStream);
  if (dataStream(i).plot == 1)
    spN = spN + 1;
  endif
endfor

j=0;
for i = 1:length(dataStream)
  if (dataStream(i).plot == 1)
    j=j+1;
    %%The function subplot returns a handle pointing to an object of type axes. 
    subPl(i) = subplot(spN,1,j);
    set(subPl(j),"box","on","title",dataStream(i).name,
                            "xlim",[1 fensterbreite]);                           
    # wenn ylim Grenzen
    if (dataStream(j).ylim != 0)
      set(subPl(j),"ylim",dataStream(i).ylim);
    endif
    # Zeichenfarbe setzen
    subLi(j) = line("color",dataStream(i).plcolor);
    #subMa(j) = line("linestyle","none","marker","o");
  endif
endfor

# externe Funktionen
# ==================
cap1 = GUI_Elements(fi_1);
displayInfo(fi_1)

inBuffer = '';                    %% Buffer serielle Schnittstelle
cr_lf = [char(13) char(10)];

disp('Open SerialPort!')
serial_01 = serialport(serialPortPath,115200);
flush(serial_01);
%configureTerminator(serial_01,"lf");

% Digitaler Filter:
% ==============================
% HP01 = Hochpass-Filter 1 Hz
% No50 = Notch-Filter 50Hz% TP40 = Tiefpass-Filter 40 Hz
% alle für fa = 200 Hz
% ==============================
% Filterkoeffizienten
HP01_ko = [ 0.9780302754084559 -1.9560605508169118 0.9780302754084559 ...
           -1.9555778328194147 0.9565432688144089 ];
No50_ko = [ 0.5857841106784856 -1.3007020142696517e-16 0.5857841106784856 ...
           -1.3007020142696517e-16 0.17156822135697122 ];
TP40_ko = [ 0.20657128726265578 0.41314257452531156 0.20657128726265578 ...
           -0.36952595241514796 0.19581110146577102 ];

% Filterimplementierung
function [adc,sp] = digitalerFilter(adc,sp,ko);
   sp(3) = sp(2); sp(2) = sp(1); sp(1) = adc; sp(6) = sp(5) ; sp(5) = sp(4);
   sp(4) = sp(1)*ko(1)+sp(2)*ko(2)+sp(3)*ko(3)-sp(5)*ko(4)-sp(6)*ko(5);
   adc   = sp(4);
endfunction

drawnow();
disp('Waiting for data!')

do
until (serial_01.NumBytesAvailable > 0);
disp('Receiving data!')
do
   % Wenn der Clear-Button gedrueckt wurde
   if (clear_data) 
     j = 0;
     for i = 1:length(dataStream);
       dataStream(i).array = [];
       dataStream(i).adc_plot = [];
       if (dataStream(i).plot > 0)
         j = j + 1;
         set(subPl(j),"xlim",[0 fensterbreite]);
       endif
     endfor
     x_index = 0;
     x_index_prev = 0;
     clear_data = 0;
   endif
   % Wenn der Save-Button gedrueckt wurde
   if (save_data)
     rec_data = 0;
     dataMatrix = [];
     for i = 1:length(dataStream)
       dataMatrix = [dataMatrix ; dataStream(i).array];
     endfor
     dataMatrix = dataMatrix';
     myfilename = uiputfile();
     save("-text",myfilename,"dataMatrix");
     save_data = 0;
   endif
   
   bytesavailable = serial_01.NumBytesAvailable;

   if (bytesavailable > min_bytesAvailable)
     inSerialPort = char(read(serial_01,bytesavailable)); %% Daten werden vom SerialPort gelesen
     inBuffer     = [inBuffer inSerialPort];              %% und an den inBuffer angehängt
     posCRLF      = index(inBuffer, cr_lf,"last");
     if (posCRLF > 0)
       % inBuffer wird zerlegt in inChar(vollstaendige Zeile(n)) + Rest = neuer inBuffer)
       inChar   = inBuffer(1:posCRLF);         %% im folgenden wird  nur inChar ausgewertet
       inBuffer = inBuffer(posCRLF+2:end);
       % inChar wird in Zeilen anhand des Limiter CRLF zerlegt
       dataRows = strsplit(inChar,cr_lf);
       % ueber alle Zeilen muss
       for i = 1:length(dataRows)
         if (rec_data)
           x_index++;
         endif
         % Zeile wird in Paare(Name:Wert) zerlegt >> auch bei mehreren Zeilen korrekt
         NameValuePairs = strsplit(dataRows{i},',');
         % alle Paare in der Liste werden angeschaut
         #length(NameValuePairs)
         for j = 1:length(NameValuePairs)
           NameValue = strsplit(NameValuePairs{j},':');
           % Sicherstellen, dass 2er-Paar vorliegt
           if (length(NameValue)==2)
             for k = 1:length(dataStream)
               if strcmp(NameValue{1},dataStream(k).name)
                 adc = str2num(NameValue{2});
                 if (dataStream(k).filter > 0)
                   if (HP01_filtered)
                     [adc,dataStream(k).HP01_sp] = digitalerFilter(adc,dataStream(k).HP01_sp,HP01_ko);
                   endif
                   if (No50_filtered)
                     [adc,dataStream(k).No50_sp] = digitalerFilter(adc,dataStream(k).No50_sp,No50_ko);
                   endif
                   if (TP40_filtered)
                     [adc,dataStream(k).TP40_sp] = digitalerFilter(adc,dataStream(k).TP40_sp,TP40_ko);
                   endif
                 endif # dataStream(k).filter > 0  
                 # 
                 # hier können die adc-Werte ausgewertet werden!
                 # callback-function individuell fuer jeden Parameter? 
                 #
                 if (rec_data)
                   dataStream(k).array(end+1)=adc;
                 endif
                 break;
               endif # strcmp
             endfor # of length(dataStream)
           endif
         endfor
       endfor # of length(dataLines)
     endif # of posCRLF
   endif  # of bytesAvaiable

   % Warten mit dem Redraw bis ausreichend neue Werte gesampelt sind
   if (x_index - x_index_prev) > min_x_index_step
     j=0;
     for i = 1:length(dataStream);
       if (dataStream(i).plot == 1)
          j=j+1;      
          % x_start darf nicht < 1 sein / X-Achse skalieren
          if (x_index > fensterbreite)
            x_start = x_index - fensterbreite;
            x_axis =  x_start:x_index;
            set(subPl(j),"xlim",[x_start x_index]);
          else
            x_start = 1;
            x_axis = 1:fensterbreite;
            set(subPl(j),"xlim",[x_start fensterbreite]);
          endif
          dataStream(i).adc_plot = dataStream(i).array(x_start:x_index);
          x_index_prev = x_index;
          % Hier wird die Linie gezeichnet
          set(subLi(j),"xdata",x_axis,"ydata",dataStream(i).adc_plot);
          drawnow();
       endif # (dataStream(i).plot==1)
     endfor
     set(cap1,"string",num2str(x_index));
   endif # of (x_index - x_index_prev) > 20

   pause(0.025);

until(quit_prg);    %% Programmende mit Quit-Button

clear serial_01;
% ============================================================================
