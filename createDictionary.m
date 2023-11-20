function streamSelector = createDictionary(dataStream)
  # Liste aller dataStream Namen erstellen fuer Dictonary
  namelist = {};
  for i = 1:length(dataStream)
    namelist{end+1} = dataStream(i).name;
  endfor
  values = 1:numel(dataStream);
  streamSelector = containers.Map(namelist,values);
endfunction
