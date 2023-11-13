# Das Skript liest in Multiplot gespeicherte Daten wieder ein
# und zeigt sie in Plot-Fenster an
#
dataStream = [];

readData = load("testsave.txt");
streamCount = (length(readData.dataMatrix)/3)

for i = 1:streamCount
  dataStream(i).name = readData.dataMatrix{(i-1)*3+1};
  dataStream(i).array = readData.dataMatrix{(i-1)*3+2};
  dataStream(i).t     = readData.dataMatrix{(i-1)*3+3};
endfor

for i = 1:length(dataStream)
  figure()
  plot(dataStream(i).t,dataStream(i).array)
endfor

