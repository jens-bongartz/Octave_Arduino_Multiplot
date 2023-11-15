#
#  Dies ist eine Octave-Skript zur Darstellung von Daten die über die
#  serielle Schnittstelle empfangen werden (z.B. ein EKG-Signal).
#  Die Daten können mit einer Kaskade von digitalen Filtern gefiltert werden.
#
#  (c) Jens Bongartz, Oktober 2023, RheinAhrCampus Remagen
#  Stand: 15.11.2023
#  ==========================================================================
pkg load instrument-control;
clear all;
#  Konfiguration der dataStreams
# obj = dataStreamClass(name,plcolor,dt,plotwidth,plot,filter)
dataStream(1) = dataStreamClass("SIM","red",5,800,1,1);
# createFilter(f_abtast,f_HP,f_NO,f_TP)
dataStream(1).createFilter(200,1,50,40);
dataStream(1).slopeDetector = 1;
##dataStream(1).peakDetector  = 1;
##dataStream(1).evalWindow = 500;           # alle 2,5 sec Threshold neu bestimmen

dataStream(2) = dataStreamClass("SIG","blue",20,200,1,1);
#dataStream(2).length = 3000;
# createFilter(f_abtast,f_HP,f_NO,f_TP)
dataStream(2).createFilter(50,1,10,20);
dataStream(2).slopeDetector = 1;

# Globale Variablen zur Programmsteuerung
global HP_filtered = 1 NO_filtered = 1 TP_filtered = 1 DQ_filtered = 0 DQ2_filtered = 0;
global quit_prg = 0 clear_data = 0 save_data = 0 rec_data = 1;

baudrate = 115200;
min_bytesAvailable = 10;
min_datasetCounter_step = 1;
# Automatische Suche nach passendem seriellen Port
disp('Seraching Serial Port ... ')
serialPortPath = checkSerialPorts(baudrate)

# Der weitere Teil wird nur ausgefuehrt, wenn serielle Schnittstelle gefunden wurde
if !isempty(serialPortPath)
  disp('Device found:');
  disp(serialPortPath);

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
  disp('Open SerialPort!')
  serial_01 = serialport(serialPortPath,baudrate);
  flush(serial_01);

  pause(2)
  drawnow();
  disp('Waiting for data!')
  # Sicherstellen, dass inBuffer nach einem CR/LF (Zeilenanfang) beginnt
  inSerialPort = '';
  inBuffer = '';
  posLF = 0;
  do
     bytesAvailable = serial_01.NumBytesAvailable;
     if (bytesAvailable > 0)
       ## Daten werden vom SerialPort gelesen
       inSerialPort = [inSerialPort char(read(serial_01,bytesAvailable))];
       posLF        = index(inSerialPort,char(10),"last");
     endif
  until (posLF > 0);
  # erst ab dem letzten \n geht es los
  inBuffer = inSerialPort(posLF+1:end);

  disp('Receiving data!')

  # Benchmarking
  Bench_Time = 2;              # Sekunden
  datasetCounter =  0;
  datasetCounter_prev = 0;
  datasetCounter_tic = 0;
  f_oct = t_toc = cpu_load = 1;
  bytesReceived = 0;
  bytesPerSecond = 0;
  tic
  t_cpu = cputime;

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
       datasetCounter = 0; datasetCounter_prev = 0;
       clear_data = 0;
     endif

     ## Wenn der Save-Button gedrueckt wurde
     if (save_data)
       rec_data = 0;
       dataMatrix = {};
       for i = 1:length(dataStream)
         dataMatrix{end+1} = dataStream(i).name;
         dataMatrix{end+1} = dataStream(i).array;
         dataMatrix{end+1} = dataStream(i).t;
       endfor
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
       posLF        = index(inBuffer,char(10),"last");
       if (posLF > 0)
         % inBuffer wird zerlegt in inChar(vollstaendige Zeile(n)) + Rest = neuer inBuffer)
         inChar   = inBuffer(1:posLF);         ## im folgenden wird  nur inChar ausgewertet
         inBuffer = inBuffer(posLF+1:end);

         if (rec_data)   # Wird vom REC-Button gesteuert
            # Regular Expression auswerten
            matches = regexp(inChar, regex_pattern, 'tokens');
            countMatches   = length(matches);       # Wert wird ausgegeben

            datasetCounter = datasetCounter + countMatches;
            dataSetCounter_tic = datasetCounter_tic + countMatches;

            for i = 1:countMatches
              streamName = matches{i}{1};
              adc        = str2num(matches{i}{2});
              sample_t   = str2num(matches{i}{3});

              j = streamSelector(streamName);
              dataStream(j).addSample(adc,sample_t);

            endfor

            # Benchmarking pro Datenzeile (alle Bench_Time Sekunden)
            if (toc > Bench_Time)
               t_toc = toc;
               f_oct = round(1/(t_toc / datasetCounter_tic));
               cpu_load = (cputime() - t_cpu);            % / t_toc *100
               t_cpu = cputime();
               datasetCounter_tic = 0;
               bytesPerSecond = round(bytesReceived / t_toc);
               bytesReceived = 0;
               tic
            endif
         endif # (rec_data)
       endif # of posCRLF
     endif  # of bytesAvaiable

     if (datasetCounter - datasetCounter_prev) > min_datasetCounter_step
       j=0;  # iteriert ueber die subPlot-Instanzen
       for i = 1:length(dataStream);
         # wenn plot == 1 dann wird das array des dataStream geplottet >> adc_plot
         if (dataStream(i).plot == 1)
            j=j+1;
            if (length(dataStream(i).array) > dataStream(i).plotwidth) # Fenster scrollt
              [adc_plot, data_t] = dataStream(i).lastSamples(dataStream(i).plotwidth);
              x_axis = [data_t(1) data_t(end)];
            else                                                       # Fenster scrollt nicht
              [adc_plot, data_t] = dataStream(i).lastSamples(dataStream(i).ar_index-1);
              x_axis = [0 dataStream(i).plotwidth*dataStream(i).dt];
            endif

            if (ishandle(fi_1))
              set(subPl(j),"xlim",x_axis);
              set(subLi(j),"xdata",data_t,"ydata",adc_plot);
              if (dataStream(i).slopeDetector || dataStream(i).peakDetector)
                #legend(subPl(j),"location","northwestoutside","string",num2str(dataStream(i).BPM));
                set(subPl(j),"title",num2str(dataStream(i).BPM),"fontsize",20);
              endif
            endif
         endif # (dataStream(i).plot==1)
       endfor
       if (ishandle(fi_1))   # Grafikausgabe nur wenn figure noch existiert
         set(cap(1),"string",num2str(datasetCounter));
         set(cap(2),"string",num2str(f_oct));
         set(cap(3),"string",num2str(t_toc));
         set(cap(4),"string",num2str(cpu_load));
         set(cap(5),"string",num2str(bytesPerSecond));
         set(cap(6),"string",num2str(countMatches));
       endif # ishandle(fi_1))
       drawnow();
       datasetCounter_prev = datasetCounter;
     endif # datasetCounter - datasetCounter_prev) > 20
     # Entlastung der CPU / des OS
     #pause(0.05);    # 1/20 Sekunde
     pause(0.025);    # 1/40 Sekunde
  until(quit_prg);    %% Programmende mit Quit-Button
  clear serial_01;
endif
