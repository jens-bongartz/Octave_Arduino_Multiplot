% Der gegebene String
text = "SIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:-106,dt:5\r\nSIM:106,dt:5\r\EKG:-100,dt:10\r\nSIM:106,dt:5\r\nPUL:108,dt:15\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\EKG:100,dt:10\r\nSIM:106,dt:5\r\nSIM:106,dt:5\r\nPUL:106,dt:15\r\n";

% Das benannte REGEX-Muster, um die Werte nach "SIM:" und "EKG:" sowie "dt:" zu extrahieren
regex_muster = '(SIM|EKG|PUL):(-?\d+),dt:(\d+)'

% Die Suche nach den Mustern im Eingabestring
treffer = regexp(text, regex_muster, 'tokens')

% Listen, um die extrahierten Werte zu speichern
sim_werte = [];
ekg_werte = [];
pul_werte = [];
sim_dt_werte = [];
ekg_dt_werte = [];
pul_dt_werte = [];

% Durch die Treffer iterieren und die Werte in die Listen schreiben
for i = 1:numel(treffer)
    typ = treffer{i}{1};
    sim_oder_ekg_wert = str2num(treffer{i}{2});
    dt_wert = str2num(treffer{i}{3});

    if strcmp(typ, 'SIM')
        sim_werte = [sim_werte, sim_oder_ekg_wert];
        sim_dt_werte = [sim_dt_werte, dt_wert];
    elseif strcmp(typ, 'EKG')
        ekg_werte = [ekg_werte, sim_oder_ekg_wert];
        ekg_dt_werte = [ekg_dt_werte, dt_wert];
    elseif strcmp(typ, 'PUL')
        pul_werte = [pul_werte, sim_oder_ekg_wert];
        pul_dt_werte = [pul_dt_werte, dt_wert];
    end
end

% Die extrahierten Werte anzeigen
disp("SIM-Werte:");
disp(sim_werte);
disp("SIM-dt-Werte:");
disp(sim_dt_werte);
disp("EKG-Werte:");
disp(ekg_werte);
disp("EKG-dt-Werte:");
disp(ekg_dt_werte);
disp("PUL-Werte:");
disp(pul_werte);
disp("PUL-dt-Werte:");
disp(pul_dt_werte);
