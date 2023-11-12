#
#  Dies ist eine Octave-Skript zur Darstellung von Daten die über die
#  serielle Schnittstelle empfangen werden (z.B. ein EKG-Signal).
#  Die Daten können mit einer Kaskade von digitalen Filtern gefiltert werden.
#
#  (c) Jens Bongartz, Oktober 2023, RheinAhrCampus Remagen
#  Stand: 06.11.2023
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
peakDetect = 1;
slopeDetect = 0;

# Digitale Filter konfigurieren
# =============================
f_abtast = 200;
#f_abtast = 13;
#f_HP = 20;                              # fuer Pulsmesser
#f_TP = 10;                              # fuer Pulsmesser
f_HP = 1;
f_TP = 40;
f_NO = 50;

# Globale Variablen zur Programmsteuerung
global HP_filtered = 1 NO_filtered = 1 TP_filtered = 1 DQ_filtered = 0 DQ2_filtered = 0;
global quit_prg = 0 clear_data = 0 save_data = 0 rec_data = 1;

HP_ko = calcHPCoeff(f_abtast,f_HP);
NO_ko = calcNotchCoeff(f_abtast,f_NO);
TP_ko = calcTPCoeff(f_abtast,f_TP);
DQ_ko  = [1 -1 0 0 0];                   # (x[n]-x[n-1])/1
DQ2_ko = [1 0 -1 0 0];                   # (x[n]-x[n-2])/(2) (1)

# Automatische Suche nach passendem seriellen Port
serialPortPath = checkSerialPorts()

# Der weitere Teil wird nur ausgefuehrt, wenn serielle Schnittstelle gefunden wurde
if !isempty(serialPortPath)
  disp('Device found:');
  disp(serialPortPath);
  #  Konfiguration der dataStreams
  # obj = dataStreamClass(name,plcolor,dt,plotwidth,plot,filter)
  dataStream(1) = dataStreamClass("EKG","red",5,800,1,1);
  #dataStream(2) = dataStreamClass("ATM","blue",1,1);

  # Liste aller dataStream Namen erstellen fuer Dictonary
  namelist = {};
  for i = 1:length(dataStream)
    namelist{end+1} = dataStream(i).name;
  endfor
  values = 1:numel(dataStream);
  streamSelector = containers.Map (namelist,values);

  # Aus den dataStream Namen wird das regex-Pattern erzeugt
  # =======================================================
  regex_pattern = '(';
  for i = 1:length(dataStream)
      regex_pattern = [regex_pattern dataStream(i).name];
      if i < length(dataStream)
          regex_pattern = [regex_pattern '|'];
      endif
  endfor
  regex_pattern = [regex_pattern '):(-?\d+),t:(\d+)'];

  # Initialisiere Plot-Fenster
  # ==========================
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
      set(subPl(j),"box","on","title",dataStream(i).name,"xlim",[0 dataStream(i).plotwidth*dataStream(i).dt]);
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
  # Peak Detection >>
  peakThreshold = 100;
  peakTrigger = 0;
  peakOld = 0;
  outBPM = 0;
  # Slope Detection
  slopeAct = 1;
  slopeOld = -1;
  slopeMax = slopeMin = 1;
  do
     ## Wenn der Clear-Button gedrueckt wurde
     if (clear_data)
       j = 0;
       for i = 1:length(dataStream);
         dataStream(i).clear;
         if (dataStream(i).plot > 0)
           j = j + 1;
           set(subPl(j),"xlim",[0 dataStream(i).plotwidth*dataStream(i).dt]);
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

            matches = regexp(inChar, regex_pattern, 'tokens');

            for i = 1:length(matches)
              streamName = matches{i}{1};
              adc        = str2num(matches{i}{2});
              sample_t   = str2num(matches{i}{3});

              j = streamSelector(streamName);

              x_index++;
              x_index_tic++;
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

              if (abs(adc) < 0.0001)                % 'dataaspectratio' Error verhindern
                 adc = 0;
              endif

              dataStream(j).addSample(adc,sample_t);

          endfor

            # Benchmarking pro Datenzeile (alle Bench_Time Sekunden)

            if (toc > Bench_Time)
               t_toc = toc;
               f_oct = round(1/(t_toc / x_index_tic));
               cpu_load = (cputime() - t_cpu);            % / t_toc *100
               t_cpu = cputime();
               x_index_tic = 0;
               bytesPerSecond = round(bytesReceived / t_toc);
               bytesReceived = 0;
               #  Schwellenwert fuer Peak-Detection
##               if (peakDetect)
##                  if (max(dataStream(1).adc_plot) > 4*std(dataStream(1).adc_plot))
##                     peakThreshold = 0.5*max(dataStream(1).adc_plot);
##                  endif
##               endif
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

            if (x_index > dataStream(i).plotwidth)                      # Fenster scrollt
              [adc_plot, data_t] = dataStream(i).lastSamples(dataStream(i).plotwidth);
              x_axis = [data_t(1) data_t(end)];
              if (ishandle(fi_1))
                set(subPl(j),"xlim",x_axis);
              endif
            else                                              # Fenster scrollt nicht
              [adc_plot, data_t] = dataStream(i).lastSamples(dataStream(i).ar_index-1);
              x_axis = [0 dataStream(i).plotwidth*dataStream(i).dt];
              if (ishandle(fi_1))
                set(subPl(j),"xlim",x_axis);
              endif
            endif

            x_index_prev = x_index;
            % Hier wird die Linie gezeichnet
            if (ishandle(fi_1))
              set(subLi(j),"xdata",data_t,"ydata",adc_plot);
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
         set(cap(6),"string",num2str(outBPM));
       endif # ishandle(fi_1))
     endif # x_index - x_index_prev) > 20
     # Entlastung der CPU / des OS
     #pause(0.05);
     pause(0.025);
  until(quit_prg);    %% Programmende mit Quit-Button
  clear serial_01;
endif
