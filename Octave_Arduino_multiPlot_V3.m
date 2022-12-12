%
%  Dies ist eine Octave-Skript zur Darstellung von Daten die über die
%  serielle Schnittstelle empfangen werden (z.B. ein EKG-Signal oder
%  Daten eines Pulsoxymetrie-Sensors).
%
%  Die Daten muessen über die serielle Schnittstelle als ASCII-Text gesendet werden
%  im Format:
%  Messwerttyp:Messwert,Messwerttyp:Messwert CR/LF
%  z.B. EKG:537,t:5
%       EKG:798,t:5
%       ...
%  oder rot:12324,ir:345676,t=80
%       rot:17899,ir:988766,t=80
%       ...
%  Die Messwerttypen muessen unter dataStream().name als String angegeben werden
%  dataStream().plot legt fest ob eine Datenreihe geplottet wird (=1 oder =0)
%  dataStream().filter legt fest ob eine Datenreihe gefiltert wird (=1 oder =0)
%  dataStream().ylim = 0 legt die y-Achse auf Autoscale ansonsten kann ein Intervall angegeben werden
%
%  min_bytesAvailable legt fest ab welcher Zahl an Bytes im inBuffer der Buffer ausgelesen wird
%  min_x_index_step legt fest nach wieviel Datenpunkte der Graph neu gezeichnet wird
%  (fuer EKG beides = 10, fuer Pulsoxy beides = 1)
%
%  fensterbreite legt fest wieviele Datenpunkte im Graph angezeigt werden
%  (EKG = 600, Pulsoxy = 200)
%
%  Die Daten können mit einer Kaskade von digitalen Filtern gefiltert werden.
%  Fuer die Filter koennen Abtastrate und Grenzfrequenzen angegeben werden
%
%  z.B. HP01_ko = calcHPCoeff(200,1);
%       No50_ko = calcNotchCoeff(200,50);
%       TP40_ko = calcTPCoeff(200,40);
%
%  Zudem werden einige Benchmarkwerte fuer die serielle Uebertragung und das Redraw angezeigt
%  cap(1) bis cap(5)
%
%  displayInfo zeigt die Eigenschaften des Grafiksystems an
%  GUI_Elements lagert den Code fuer GUI-Elemente aus
%
%  (c) Jens Bongartz, September 2022, RheinAhrCampus Remagen
%  Stand: 12.12.2022
%  ==========================================================================
pkg load instrument-control;
clear all;
#
# Serieller Port muss von Hand eingestellt werden
# ===============================================
# Windows
serialPortPath = "COM4";
# MacOSX
#serialPortPath = "/dev/cu.usbmodem142401";
#serialPortPath = "/dev/tty.usbserial-110";
#serialPortPath = "/dev/tty.usbserial-A50285BI";
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
dataStream(2).ylim = 0;
dataStream(2).adc_plot = [ ];
dataStream(2).filter = 1;
dataStream(2).HP01_sp = [0 0 0 0 0 0];                    % Filter-Speicher
dataStream(2).No50_sp = [0 0 0 0 0 0];                    % Filter-Speicher
dataStream(2).TP40_sp = [0 0 0 0 0 0];
##
dataStream(3).name = "t";
dataStream(3).array = [ ];
dataStream(3).plot = 1;
dataStream(3).plcolor = "black";
#dataStream(3).ylim = [-15 15];
dataStream(3).ylim = 0;
dataStream(3).adc_plot = [ ];
dataStream(3).filter = 0;
dataStream(3).HP01_sp = [0 0 0 0 0 0];                    % Filter-Speicher
dataStream(3).No50_sp = [0 0 0 0 0 0];                    % Filter-Speicher
dataStream(3).TP40_sp = [0 0 0 0 0 0];                    % Filter-Speicher

numDataStream = length(dataStream);

#min_bytesAvailable = 10;
#min_x_index_step = 10;
Bench_Time = 2;              % Sekunden
min_bytesAvailable = 1;
min_x_index_step   = 1;
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
    if (sum(dataStream(j).ylim != 0))
      set(subPl(j),"ylim",dataStream(i).ylim);
    endif
    # Zeichenfarbe setzen
    subLi(j) = line("color",dataStream(i).plcolor);
    #subMa(j) = line("linestyle","none","marker","o");
  endif
endfor

# externe Funktionen
# ==================
cap = GUI_Elements(fi_1);       % cap ist ein Array von captions!
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
HP01_ko = calcHPCoeff(200,1);

No50_ko = calcNotchCoeff(200,50);

TP40_ko = calcTPCoeff(200,40);

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

disp('Bytes available!')

% Sicherstellen, dass inBuffer nach einem CR/LF (Zeilenanfang) beginnt

inSerialPort = '';
do
   bytesAvailable = serial_01.NumBytesAvailable;
   if (bytesAvailable > 0)

     inSerialPort = [inSerialPort char(read(serial_01,bytesAvailable))]; %% Daten werden vom SerialPort gelesen
     posCRLF      = index(inSerialPort, cr_lf,"last");
   endif
until (posCRLF > 0);

inBuffer = inSerialPort(posCRLF+2:end);

disp('Receiving data! Lines synced!')

% Benchmarking
%
x_index_tic = 0;
f_oct = t_toc = cpu_load = 0;
bytesReceived = 0;
bytesPerSecond = 0;
tic
t_cpu = cputime;

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
     if (myfilename != 0)
        save("-text",myfilename,"dataMatrix");
     endif
     save_data = 0;
   endif

   bytesAvailable = serial_01.NumBytesAvailable;

   if (bytesAvailable > min_bytesAvailable)
     bytesReceived = bytesReceived + bytesAvailable;
     inSerialPort = char(read(serial_01,bytesAvailable)); %% Daten werden vom SerialPort gelesen
     inBuffer     = [inBuffer inSerialPort];              %% und an den inBuffer angehängt
     posCRLF      = index(inBuffer, cr_lf,"last");
     if (posCRLF > 0)
       % inBuffer wird zerlegt in inChar(vollstaendige Zeile(n)) + Rest = neuer inBuffer)
       inChar   = inBuffer(1:posCRLF);         %% im folgenden wird  nur inChar ausgewertet
       inBuffer = inBuffer(posCRLF+2:end);

       if (rec_data) % Dieser Teil muss nur ausgefuehrt werden, wenn Aufnahme aktiv ist
         cellStrArray = strsplit(inChar,{cr_lf,",",":"});
         numDataLines = floor(length(cellStrArray)/(numDataStream*2)); % pro dataStream name + value
         checkCount = mod(length(cellStrArray),numDataStream);
         if (checkCount == 0)
           cellIndex = 1;
           for i = 1:numDataLines
             x_index++;
             x_index_tic++;
             for j = 1:numDataStream
                if (strcmp(cellStrArray{cellIndex},dataStream(j).name))
                  adc = str2num(cellStrArray{cellIndex+1});

                  # Filterblock HP / Notch / TP
                  if (dataStream(j).filter > 0)
                    if (HP01_filtered)
                      [adc,dataStream(j).HP01_sp] = digitalerFilter(adc,dataStream(j).HP01_sp,HP01_ko);
                    endif
                    if (No50_filtered)
                      [adc,dataStream(j).No50_sp] = digitalerFilter(adc,dataStream(j).No50_sp,No50_ko);
                    endif
                    if (TP40_filtered)
                      [adc,dataStream(j).TP40_sp] = digitalerFilter(adc,dataStream(j).TP40_sp,TP40_ko);
                    endif
                  endif # dataStream(k).filter > 0
                  dataStream(j).array(x_index)=adc;
                  if (abs(adc) < 0.0001)                % 'dataaspectratio' Error verhindern
                    dataStream(j).array(x_index)=0;
                  endif

                else
                  disp('dataStream corrupted (Name Error)!');
                endif
                cellIndex = cellIndex + 2;
             endfor % numDataStreams
           endfor % numDataLines
         else
           disp('dataStream corrupted (incomplete Lines)!');
         endif
         % Benchmarking pro Datenzeile (x_index)
         % =====================================
         if (toc > Bench_Time)
           t_toc = toc;
           f_oct = round(1/(t_toc / x_index_tic));
           cpu_load = (cputime() - t_cpu);            % / t_toc *100
           t_cpu = cputime();
           x_index_tic = 0;
           bytesPerSecond = round(bytesReceived / t_toc);
           bytesReceived = 0;
           tic
         endif
         % ==============
       endif # (rec_data)
     endif # of posCRLF
   endif  # of bytesAvaiable

   % Grafikausgaben werden nur durchgefuehrt, wenn x_index hochzaehlt (rec_data = TRUE)
   % Vor der Grafikausgabe sollte geprueft werden, ob figure noch offen ist >> ishandle(fi_1)

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
            if (ishandle(fi_1))
              set(subPl(j),"xlim",[x_start x_index]);
            endif
          else
            x_start = 1;
            x_axis = 1:fensterbreite;
            if (ishandle(fi_1))
              set(subPl(j),"xlim",[x_start fensterbreite]);
            endif
          endif
          dataStream(i).adc_plot = dataStream(i).array(x_start:x_index);
          x_index_prev = x_index;
          % Hier wird die Linie gezeichnet
          if (ishandle(fi_1))
            set(subLi(j),"xdata",x_axis,"ydata",dataStream(i).adc_plot);
          endif
          drawnow();
       endif # (dataStream(i).plot==1)
     endfor
     if (ishandle(fi_1))   # Grafikausgabe nur wenn figure noch existiert
       set(cap(1),"string",num2str(x_index));
       set(cap(2),"string",num2str(f_oct));
       set(cap(3),"string",num2str(t_toc));
       set(cap(4),"string",num2str(cpu_load));
       set(cap(5),"string",num2str(bytesPerSecond));
     endif # ishandle(fi_1))
   endif # x_index - x_index_prev) > 20

   %pause(0.05);
   pause(0.025);

until(quit_prg);    %% Programmende mit Quit-Button

clear serial_01;
% ============================================================================
