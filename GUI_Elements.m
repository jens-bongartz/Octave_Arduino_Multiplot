function cap1 = GUI_Elements(fi_1)
  % ============
  % GUI-Elemente
  % ============
   
  % "HP 1Hz " Checkbox
  % ===================
  cb_HP01 = uicontrol(fi_1,"style","checkbox","string","HP 1 Hz", ...
                      "callback",@cb_HP01_changed,"position",[10,0,90,30]);
  
  function cb_HP01_changed;
    global HP01_filtered;
    HP01_filtered = not(HP01_filtered);
  endfunction
  
  % "Notch 50Hz" Checkbox
  cb_No50 = uicontrol(fi_1,"style","checkbox","string","Notch 50Hz", ...
                      "callback",@cb_No50_changed,"position",[110,0,90,30]);
  
  function cb_No50_changed;
    global No50_filtered;
    No50_filtered = not(No50_filtered);
  endfunction
  
  % "TP 40Hz" Checkbox
  cb_TP40 = uicontrol(fi_1,"style","checkbox","string","TP 40Hz", ...
                    "callback",@cb_TP40_changed,"position",[210,0,90,30]);
  
  function cb_TP40_changed;
    global TP40_filtered;
    TP40_filtered = not(TP40_filtered);
  endfunction
  % Clear-Button
  Clear_Button = uicontrol(fi_1,"style","pushbutton","string","Clear",...
                          "callback",@Clear_Button_pressed,"position",[310,0,50,30]);
  
  function Clear_Button_pressed
     global clear_data;
     clear_data = 1;
  endfunction
  % Save-Button
  Save_Button = uicontrol(fi_1,"style","pushbutton","string","Save",...
                          "callback",@Save_Button_pressed,"position",[370,0,50,30]);
  
  function Save_Button_pressed
    global save_data;
    save_data = 1;
  endfunction
  % Rec-Button
  Rec_Button = uicontrol(fi_1,"style","pushbutton","string","Rec",...
                          "callback",@Rec_Button_pressed,"position",[430,0,50,30]);
  
  function Rec_Button_pressed
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
  cap1 = uicontrol(fi_1,"style","text","string","BPM:","position",[490,0,50,30]);
endfunction

