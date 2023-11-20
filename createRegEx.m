function regex_pattern = createRegEx(dataStream)
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
endfunction
