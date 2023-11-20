#        SerialPortDataStreamer V 1.0  (SPDS)
#
#  (c) Jens Bongartz, 2023, RheinAhrCampus Remagen
#                Stand: 19.11.2023
#  ================================================

pkg load instrument-control;
clear all;
# obj = dataStreamClass(name,plcolor,dt,plotwidth,plot,filter)
# createFilter(f_abtast,f_HP,f_NO,f_TP)
#dataStream(2).length = 3000;
##dataStream(1).peakDetector  = 1;
##dataStream(1).evalWindow = 500;           # alle 2,5 sec Threshold neu bestimmen

dataStream(1) = dataStreamClass("SIM","red",5,800,1,1);
dataStream(1).createFilter(200,1,50,40);
dataStream(1).slopeDetector = 1;

dataStream(2) = dataStreamClass("SIG","blue",20,200,1,1);
dataStream(2).createFilter(50,1,10,20);
dataStream(2).slopeDetector = 1;

streamSelector = createDictionary(dataStream);
regex_pattern = createRegEx(dataStream);

# Globale Variablen zur Programmsteuerung
global HP_filtered = 1 NO_filtered = 1 TP_filtered = 1 DQ_filtered = 0 DQ2_filtered = 0;
global quit_prg = 0 clear_data = 0 save_data = 0 rec_data = 1;

Bench_Time = 2;              # Sekunden
Plot_Time = 0.1;
SerialPort_Time = 0.1;
Pause_Time = 0.05;

# Suche nach passendem seriellen Port
baudrate = 115200;
disp('Searching Serial Port ... ')
serialPortPath = checkSerialPorts(baudrate)

# Der weitere Teil wird nur ausgefuehrt, wenn serielle Schnittstelle gefunden wurde
if !isempty(serialPortPath)
  disp('Device found:');
  disp(serialPortPath);

  # Graphikfenster initialisieren
  plotGraph = plotGraphClass(dataStream);
  cap = GUI_Elements(plotGraph.fi_1);       % cap ist ein Array von captions!
  displayInfo(plotGraph.fi_1);

  # Oeffnen serialPort
  disp('Open SerialPort!')
  serial_01 = serialport(serialPortPath,baudrate);
  flush(serial_01);
  pause(2)
  drawnow();
  disp('Waiting for data!')
  # Sicherstellen, dass inBuffer nach einem CR/LF (Zeilenanfang) beginnt
  inSerialPort = ''; inBuffer = ''; posLF = 0;
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

  # Hauptschleife
  # =============
  datasetCounter = 0;
  datasetCounter_tic = 0; bytesReceived = 0;

  bench_tic = tic(); plot_tic = tic(); serial_tic = tic();
  [t_cpu_prev,t_user_prev,t_sys_prev] = cputime();
  do
     # Button checken
     # ===============
     ## Save-Button
     if (clear_data)
       j = 0;
       for i = 1:length(dataStream);
         dataStream(i).clear;
         if (dataStream(i).plot > 0)
           j = j + 1;
           set(plotGraph.subPl(j),"xlim",[0 dataStream(i).plotwidth*dataStream(i).dt]);
         endif
       endfor
       datasetCounter = 0; datasetCounter_prev = 0;
       clear_data = 0;
     endif
     ## Save-Button
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

     # SerialPort auslesen
     # ===================
     s_toc = toc(serial_tic);
     if (s_toc > SerialPort_Time)
       bytesAvailable = serial_01.NumBytesAvailable;
       if (bytesAvailable > 0)
         # bytesReceived wird addiert und bei jedem Bench_Time zurueckgesetzt
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
              # datasetCounter laeuft durch
              datasetCounter = datasetCounter + countMatches;
              # datasetCounter_tic wird nach jedem Bench_Time zurueckgesetzt
              datasetCounter_tic = datasetCounter_tic + countMatches;
              # Matches den dataStreams zuordnen
              for i = 1:countMatches
                streamName = matches{i}{1};
                adc        = str2num(matches{i}{2});
                sample_t   = str2num(matches{i}{3});
                # Sample einem dataStream zuweisen
                j = streamSelector(streamName);
                # Hier uebernimmt dataStream die Arbeit
                dataStream(j).addSample(adc,sample_t);
              endfor
           endif # (rec_data)
         endif # of posCRLF
       endif  # of bytesAvaiable
       serial_tic = tic();
     endif # s_toc

     # Plot-Graphikfenster
     # ===================
     p_toc = toc(plot_tic);
     if (p_toc > Plot_Time)
     #if (datasetCounter - datasetCounter_prev) > min_datasetCounter_step
       plotGraph.draw(dataStream);
       if (ishandle(plotGraph.fi_1))   # Grafikausgabe nur wenn figure noch existiert
         set(cap(1),"string",num2str(datasetCounter));
       endif
       drawnow();
       #datasetCounter_prev = datasetCounter;
       plot_tic = tic();
     endif # p_toc
     # Entlastung der CPU
     pause(Pause_Time);

     # Benchmarking
     # ============
     b_toc = toc(bench_tic);
     if (b_toc > Bench_Time)
       # Empfangene Bytes pro Sekunde
       f_oct = round(datasetCounter_tic/b_toc);  datasetCounter_tic = 0;
       bytesPerSecond = round(bytesReceived / b_toc); bytesReceived = 0;

       [t_cpu,t_user,t_sys] = cputime();
       user_load = t_user - t_user_prev; sys_load = t_sys - t_sys_prev;
       t_cpu_prev = t_cpu; t_user_prev = t_user; t_sys_prev = t_sys;
       if (ishandle(plotGraph.fi_1))   # Grafikausgabe nur wenn figure noch existiert
         #set(cap(1),"string",num2str(datasetCounter));
         set(cap(2),"string",num2str(f_oct));
         set(cap(3),"string",num2str(b_toc));
         set(cap(4),"string",num2str(user_load));       # untere Wert
         #set(cap(7),"string",num2str(sys_load));        # obere Wert
         set(cap(5),"string",num2str(bytesPerSecond));
         set(cap(6),"string",num2str(countMatches));
       endif # ishandle(fi_1))
       bench_tic=tic();                   # neue Zeitschleife
     endif # b_toc

  until(quit_prg);    %% Programmende mit Quit-Button
  clear serial_01;
endif
