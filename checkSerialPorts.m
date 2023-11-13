function portReturn = checkSerialPorts()
  pkg load instrument-control
  fehler = false;
  ports = serialportlist();
  portIndex = 1;
  port_found = false;

  while(portIndex <= length(ports) && !port_found)
    #disp(ports{portIndex})
    try
      serial_01 = serialport(ports{portIndex});
    catch
      #disp("Fehler aufgetreten:")
      #disp(lasterror.message)
      fehler = true;
    end_try_catch
    if (fehler == false)
##      pause(1)
##      flush(serial_01);
      pause(2)
      bytesAvailable = serial_01.NumBytesAvailable;
      if (bytesAvailable > 0)
        inSerialPort = char(read(serial_01,bytesAvailable));
        firstCRLF    = index(inSerialPort, "\r\n","first");
        lastCRLF     = index(inSerialPort, "\r\n","last");
        if (lastCRLF > firstCRLF)
          inChar   = inSerialPort(firstCRLF:lastCRLF);
          values   = strsplit(inChar, {':',',','\n','\r'});
          data = unique(values);
          filtered_data = {};
          for i = 1:numel(data)
            if !any(isstrprop(data{i}, 'digit'))
              if !isempty(data{i})
                filtered_data{end+1} = data{i};
              endif
            endif
          endfor
          if !isempty(filtered_data)
            msg = [serial_01.Port ,"\n"];
            for i = 1:length(filtered_data)
              msg = [msg,filtered_data{i},";"];
            endfor
            portReturn = serial_01.Port;
            port_found = true;
          endif
          #disp(filtered_data)
        endif
      endif
      clear serial_01;
    else
      fehler = false;
    endif
    portIndex = portIndex + 1;
  endwhile
  if (port_found)
    waitfor(msgbox(msg,"SerialPort"));
    return;
  else
    waitfor(msgbox("No device found","SerialPort"));
    portReturn = '';
    return;
  endif
endfunction
