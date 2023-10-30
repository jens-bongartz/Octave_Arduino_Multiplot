# Das Skript liest in Multiplot gespeicherte Daten wieder ein
# und zeigt sie in Plot-Fenster an
#
readData = load("signal02.txt");
col_1 = readData.dataMatrix(:,1);
col_2 = readData.dataMatrix(:,2);
figure 1
plot(col_1)
figure 2
plot(col_2)

