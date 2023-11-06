% Der gegebene String
text = "SIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\n\
        SIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\n\
        SIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\n\
        SIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\n\
        SIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\n\
        SIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\n\
        SIM:106,dt:5\r\nSIM:106,dt:5\r\nEKG:106,dt:10\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\n\
        SIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\n\
        SIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\n\
        SIM:106,dt:5\r\nEKG:106,dt:10\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\n";

% Die zu suchenden Zeichenfolgen
suchzeichenfolgen = {'SIM', 'EKG'};
anzahl_suchbegriffe = numel(suchzeichenfolgen);

% Das benannte REGEX-Muster, um die Werte nach den Zeichenfolgen und "dt:" zu extrahieren
regex_muster = '(';
for i = 1:anzahl_suchbegriffe
    regex_muster = [regex_muster suchzeichenfolgen{i} ':(\d+),dt:(\d+)'];
    if i < anzahl_suchbegriffe
        regex_muster = [regex_muster '|'];
    end
end
regex_muster = [regex_muster ')'];

% Die Suche nach den Mustern im Eingabestring
treffer = regexp(text, regex_muster, 'tokens');

% Arrays, um die extrahierten Werte zu speichern
werte_arrays = cell(1, anzahl_suchbegriffe * 2); % Hier *2, da es jeweils "SIM" und "EKG" gibt

% Durch die Treffer iterieren und die Werte in die Arrays schreiben
for i = 1:numel(treffer)
    typ = treffer{i}{1};
    wert_1 = str2num(treffer{i}{2});
    wert_2 = str2num(treffer{i}{3});

    index_typ = find(strcmp(suchzeichenfolgen, typ)); % Index des Suchbegriffs
    index_in_array = (index_typ - 1) * 2 + 1; % Index im Werte-Array

    werte_arrays{index_in_array} = [werte_arrays{index_in_array}, wert_1];
    werte_arrays{index_in_array + 1} = [werte_arrays{index_in_array + 1}, wert_2];
end

% Die extrahierten Werte anzeigen
for i = 1:numel(suchzeichenfolgen)
    disp([suchzeichenfolgen{i} '-Werte:']);
    disp(werte_arrays{(i - 1) * 2 + 1}); % Werte
    disp([suchzeichenfolgen{i} '-dt-Werte:']);
    disp(werte_arrays{i * 2}); % dt-Werte
end
