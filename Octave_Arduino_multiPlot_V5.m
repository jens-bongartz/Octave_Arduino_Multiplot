#
#  Dies ist eine Octave-Skript zur Darstellung von Daten die über die
#  serielle Schnittstelle empfangen werden (z.B. ein EKG-Signal).
#  Die Daten können mit einer Kaskade von digitalen Filtern gefiltert werden.
#
#  (c) Jens Bongartz, Oktober 2023, RheinAhrCampus Remagen
#  Stand: 29.10.2023
#  ==========================================================================
#  Am 30.10.2023 Reihenfolge der digitalen Filter verändert
#  ist: NO > TP > HP
#  war: HP > NO > TP
#  function digitalerFilter ist in separate Datei ausgelagert
pkg load instrument-control;
clear all;
#
baudrate = 115200;
min_bytesAvailable = 10;
min_x_index_step   = 1;
beatDetect = 1;
extrDetect = 0;

# Digitale Filter konfigurieren
# =============================
f_abtast = 200;
#f_abtast = 13;
f_HP = 20;
f_TP = 10;
f_NO = 50;

HP_ko = calcHPCoeff(f_abtast,f_HP);
NO_ko = calcNotchCoeff(f_abtast,f_NO);
TP_ko = calcTPCoeff(f_abtast,f_TP);
DQ_ko  = [1 -1 0 0 0];                   # (x[n]-x[n-1])/1
DQ2_ko = [1 0 -1 0 0];                   # (x[n]-x[n-2])/(2) (1)

# Globale Variablen zur Programmsteuerung
global HP_filtered = 1;
global NO_filtered = 1;
global TP_filtered = 1;
global DQ_filtered = 0;
global DQ2_filtered = 1;
global quit_prg = 0;
global clear_data = 0;
global save_data = 0;
global rec_data = 1;

# Automatische Suche nach passendem seriellen Port
serialPortPath = checkSerialPorts()
# Windows:  serialPortPath = "COM5";
# MacOSX:   serialPortPath = "/dev/cu.usbmodem142401";
#           serialPortPath = "/dev/tty.usbserial-130";
#           serialPortPath = "/dev/tty.usbserial-A50285BI";
# Linux:    serialPortPath = "/dev/ttyUSB0";

# Der weitere Teil wird nur ausgefuehrt, wenn serielle Schnittstelle gefunden wurde
if !isempty(serialPortPath)
  disp('Device found:');
  disp(serialPortPath);
  #  Konfiguration der dataStreams
  # Simulation  = SIM / dt      - fensterbreite = 1000
  # Pulsoxy     = rot / ir / t  - fensterbreite = 400
  # EKG         = EKG / t       - fensterbreite = 1000
  # Atmung      = ATM / t       - fensterbreite = 400
  # Beat        = ATM / t       - fensterbreite = 1000

# obj = dataStreamClass(name,plcolor,plot,filter)
  dataStream(1) = dataStreamClass("PUL","red",1,1);
  dataStream(2) = dataStreamClass("t","blue",0,0);
  dataStream(1).ylim = [-20 20];  # auskommentieren wenn automatisch
  fensterbreite = 1000;
##  dataStream(1) = dataStreamClass("ir","blue",1,1);
##  dataStream(2) = dataStreamClass("rot","red",1,1);
##  dataStream(3) = dataStreamClass("t","black",0,0);
##  fensterbreite = 200;
##  dataStream(1) = dataStreamClass("ATM","blue",1,1);
##  dataStream(2) = dataStreamClass("t","red",0,0);
##  fensterbreite = 400;

  # Aus den dataStream Namen wird das regex-Pattern erzeugt
  # =======================================================
  regex_pattern = "";
  for i = 1:length(dataStream)
      regex_pattern = [regex_pattern dataStream(i).name ":(-?\\d+)"];
      if i < length(dataStream)
          regex_pattern = [regex_pattern ","];
      endif
  endfor

  % Initialisiere Plot-Fenster
  % ==========================
  graphics_toolkit("qt");
  fi_1 = figure(1);
  clf
  # Bestimmung wieviele Plots gezeichnet werden >> fuer subplot()
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
      ## The function subplot returns a handle pointing to an object of type axes.
      subPl(j) = subplot(spN,1,j);
      set(subPl(j),"box","on","title",dataStream(i).name,"xlim",[1 fensterbreite]);
      # wenn ylim Grenzen nutzt
      if (sum(dataStream(j).ylim != 0))
        set(subPl(j),"ylim",dataStream(i).ylim);
      endif
      # Zeichenfarbe setzen
      subLi(j) = line("linewidth",2,"color",dataStream(i).plcolor);
    endif
  endfor

  # externe Funktionen

  cap = GUI_Elements(fi_1);       % cap ist ein Array von captions!
  displayInfo(fi_1)

  # Oeffnen serialPort
  inBuffer = '';                    %% Buffer serielle Schnittstelle
  cr_lf = [char(13) char(10)];

  if (!isempty(serialPortPath))
    disp('Open SerialPort!')
    serial_01 = serialport(serialPortPath,baudrate);
    flush(serial_01);
  endif

  pause(2)
  drawnow();
  disp('Waiting for data!')

  do
  until (serial_01.NumBytesAvailable > 20);

  disp('Bytes available!')

  # Sicherstellen, dass inBuffer nach einem CR/LF (Zeilenanfang) beginnt
  inSerialPort = '';
  do
     bytesAvailable = serial_01.NumBytesAvailable;
     if (bytesAvailable > 0)
       ## Daten werden vom SerialPort gelesen
       inSerialPort = [inSerialPort char(read(serial_01,bytesAvailable))];
       posCRLF      = index(inSerialPort, cr_lf,"last");
     endif
  until (posCRLF > 0);

  inBuffer = inSerialPort(posCRLF+2:end);

  disp('Receiving data! Lines synced!')

  # Variablen fuer die do ... until Schleife
  # =========================================
  Bench_Time = 2;              # Sekunden
  x_index =  0;
  x_index_prev = 0;

  # Benchmarking
  x_index_tic = 0;
  f_oct = t_toc = cpu_load = 1;
  bytesReceived = 0;
  bytesPerSecond = 0;
  tic
  t_cpu = cputime;
  # Beat Detection >>
  beatThreshold = 100;
  beatTrigger = 0;
  beatOld = 0;
  beatBPM = 0;
  # Extrema Detection
  slopeAct = 1;
  slopeOld = -1;
  slopeMax = slopeMin = 1;
  do
     ## Wenn der Clear-Button gedrueckt wurde
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
       slopeMax = slopeMin = 1;
     endif

     ## Wenn der Save-Button gedrueckt wurde
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
       ## Daten werden vom SerialPort gelesen
       inSerialPort = char(read(serial_01,bytesAvailable));
       ## und an den inBuffer angehängt
       inBuffer     = [inBuffer inSerialPort];
       posCRLF      = index(inBuffer, cr_lf,"last");
       if (posCRLF > 0)
         % inBuffer wird zerlegt in inChar(vollstaendige Zeile(n)) + Rest = neuer inBuffer)
         inChar   = inBuffer(1:posCRLF);         ## im folgenden wird  nur inChar ausgewertet
         inBuffer = inBuffer(posCRLF+2:end);

         if (rec_data)   # Wird vom REC-Button gesteuert
            # inChar wird per regex nach Zeichenketten durchsucht
            matches = regexp(inChar, regex_pattern, 'tokens');
            # matches ist eine Liste aus Datensaetzen in denen jeder dataStream(1..n) vorkommt
            # "EKG:234,t:5 -- EKG:345,t:5 --- EKG:456,t:5 ---"
            # matches = [234,5],[345,5],[456,5]
            for i = 1:length(matches)
              x_index++;
              x_index_tic++;
              for j = 1:length(dataStream)
                adc = str2num(matches{i}{j});
                if (dataStream(j).filter > 0)
                   if (NO_filtered)
                      [adc,dataStream(j).NO_sp] = digitalerFilter(adc,dataStream(j).NO_sp,NO_ko);
                   endif
                   if (TP_filtered)
                      [adc,dataStream(j).TP_sp] = digitalerFilter(adc,dataStream(j).TP_sp,TP_ko);
                   endif
                   if (HP_filtered)
                      [adc,dataStream(j).HP_sp] = digitalerFilter(adc,dataStream(j).HP_sp,HP_ko);
                   endif
                   if (DQ_filtered)
                      [adc,dataStream(j).DQ_sp] = digitalerFilter(adc,dataStream(j).DQ_sp,DQ_ko);
                   endif
                   if (DQ2_filtered)
                      [adc,dataStream(j).DQ2_sp] = digitalerFilter(adc,dataStream(j).DQ2_sp,DQ2_ko);
                   endif
                endif # dataStream(k).filter > 0
                # Daten werden fuer alle dataStreams in das array uebernommen

                dataStream(j).array(x_index)=adc;

                if (abs(adc) < 0.0001)                % 'dataaspectratio' Error verhindern
                   dataStream(j).array(x_index)=0;
                endif

                # Detectoren laufen nur auf dataStream(1)
                if (j == 1)  && (x_index > 2) # nur dataStream(1)
                  # extremeDetection
                  if (extrDetect)
                     slopeAct = sign(dataStream(1).array(x_index)-dataStream(1).array(x_index-1));
                     if (slopeAct ~= slopeOld)
                       if (slopeAct < slopeOld) # Ubergang 1 >> -1 = Maximum
                         beatBPM = round(60/((x_index-slopeMax)*(1/f_oct)));
                         slopeMax = x_index;
                         #irAC  = dataStream(1).array(slopeMax)-dataStream(1).array(slopeMin)
                         #redAC = dataStream(2).array(slopeMax-1)-dataStream(2).array(slopeMin)
                       else                     # Minimum
                         slopeMin = x_index;
                       endif
                       slopeOld = slopeAct;
                     endif
                  endif
                  # beatDetection
                  if (beatDetect)
                    if ((dataStream(1).array(x_index) > beatThreshold) && !beatTrigger)
                      # Doppel-Peaks unterdruecken
                      if (x_index - beatOld) > (f_abtast / 10)
                         beatIntervall = x_index - beatOld;
                         beatOld = x_index;
                         beatBPM = round(60/(beatIntervall*(1/f_oct)));
                         beatTrigger = 1;
                      endif
                    endif
                    if ((dataStream(1).array(x_index) < beatThreshold) && beatTrigger)
                      beatTrigger = 0;
                    endif
                  endif
                endif
              endfor #j = 1:length(dataStream)
            endfor #i

            # Benchmarking pro Datenzeile (alle Bench_Time Sekunden)

            if (toc > Bench_Time)
               t_toc = toc;
               f_oct = round(1/(t_toc / x_index_tic));
               cpu_load = (cputime() - t_cpu);            % / t_toc *100
               t_cpu = cputime();
               x_index_tic = 0;
               bytesPerSecond = round(bytesReceived / t_toc);
               bytesReceived = 0;
               #  Schwellenwert fuer Beat-Detection
               if (beatDetect)
                  if (max(dataStream(1).adc_plot) > 4*std(dataStream(1).adc_plot))
                     beatThreshold = 0.5*max(dataStream(1).adc_plot);
                  endif
               endif
               tic
            endif
         endif # (rec_data)
       endif # of posCRLF
     endif  # of bytesAvaiable

     # Grafikausgaben werden nur durchgefuehrt, wenn x_index hochzaehlt (rec_data = TRUE)
     # Vor der Grafikausgabe sollte geprueft werden, ob figure noch offen ist >> ishandle(fi_1)
     # Warten mit dem Redraw bis ausreichend neue Werte gesampelt sind
     if (x_index - x_index_prev) > min_x_index_step
       j=0;  # iteriert ueber die subPlot-Instanzen
       for i = 1:length(dataStream);
         # wenn plot == 1 dann wird das array des dataStream geplottet >> adc_plot
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
            # passender Teil des array wird in adc_plot umkopiert
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
         set(cap(6),"string",num2str(beatBPM));
       endif # ishandle(fi_1))
     endif # x_index - x_index_prev) > 20
     # Entlastung der CPU / des OS
     #pause(0.05);
     pause(0.025);
  until(quit_prg);    %% Programmende mit Quit-Button
  clear serial_01;
endif
