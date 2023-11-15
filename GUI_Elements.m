function cap = GUI_Elements(fi_1)
  % ============
  % GUI-Elemente
  % ============

  % "HP" Checkbox
  % ===================
  global HP_filtered;
  cb_HP = uicontrol(fi_1,"style","checkbox","string","HP", ...
                      "callback",@cb_HP_changed,"position",[10,0,90,30], ...
                      "value", HP_filtered);

  function cb_HP_changed(~,~);
    HP_filtered = not(HP_filtered);
  endfunction

  % "Notch" Checkbox
  global NO_filtered;
  cb_NO = uicontrol(fi_1,"style","checkbox","string","NO", ...
                      "callback",@cb_NO_changed,"position",[60,0,90,30], ...
                      "value", NO_filtered);

  function cb_NO_changed(~,~);
    NO_filtered = not(NO_filtered);
  endfunction

  % "TP" Checkbox
  global TP_filtered;
  cb_TP = uicontrol(fi_1,"style","checkbox","string","TP", ...
                    "callback",@cb_TP_changed,"position",[110,0,90,30], ...
                    "value", TP_filtered);

  function cb_TP_changed(~,~);
    TP_filtered = not(TP_filtered);
  endfunction

  global DQ_filtered;
  cb_DQ = uicontrol(fi_1,"style","checkbox","string","DQ", ...
                    "callback",@cb_DQ_changed,"position",[160,0,90,30], ...
                    "value", DQ_filtered);

  function cb_DQ_changed(~,~);
    DQ_filtered = not(DQ_filtered);
  endfunction

  global DQ2_filtered;
  cb_DQ2 = uicontrol(fi_1,"style","checkbox","string","DQ2", ...
                    "callback",@cb_DQ2_changed,"position",[210,0,90,30], ...
                    "value", DQ2_filtered);

  function cb_DQ2_changed(~,~);
    DQ2_filtered = not(DQ2_filtered);
  endfunction

  % Clear-Button
  Clear_Button = uicontrol(fi_1,"style","pushbutton","string","Clear",...
                          "callback",@Clear_Button_pressed,"position",[310,0,50,30]);

  function Clear_Button_pressed(~,~);
     global clear_data;
     clear_data = 1;
  endfunction
  % Save-Button
  Save_Button = uicontrol(fi_1,"style","pushbutton","string","Save",...
                          "callback",@Save_Button_pressed,"position",[370,0,50,30]);

  function Save_Button_pressed(~,~);
    global save_data;
    save_data = 1;
  endfunction
  % Rec-Button
  Rec_Button = uicontrol(fi_1,"style","pushbutton","string","Rec",...
                          "callback",@Rec_Button_pressed,"position",[430,0,50,30]);

  function Rec_Button_pressed(~,~);
    global rec_data;
    rec_data = not(rec_data);
  endfunction

  % Wenn das figure-Fenster geschlossen wird, soll auch das Programm beendet werden
  set(fi_1,"closerequestfcn",@onclosefigure);
  function onclosefigure(h,e)
    global quit_prg;
    quit_prg = 1;
    delete(fi_1)
  endfunction
  % ========================
  cap(1) = uicontrol(fi_1,"style","text","string","Index","position",[490,0,50,30]);
  cap(2) = uicontrol(fi_1,"style","text","string","f_a","position",[550,0,50,30]);
  cap(3) = uicontrol(fi_1,"style","text","string","tic","position",[610,0,50,30]);
  cap(4) = uicontrol(fi_1,"style","text","string","cpu","position",[670,0,50,30]);
  cap(5) = uicontrol(fi_1,"style","text","string","cpu","position",[730,0,50,30]);
  cap(6) = uicontrol(fi_1,"style","text","string","BPM","position",[790,0,50,30]);
endfunction

