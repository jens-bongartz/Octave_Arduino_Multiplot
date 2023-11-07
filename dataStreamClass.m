% dataStreamClass.m >> This is a handle-Class!
classdef dataStreamClass < handle
    properties
        name = "";
        array = [];              # in array[] stehen alle Messdaten seit CLEAR
        ar_index = 1;
        adc_plot = [];
        plot = 1;
        plcolor = "";
        #ylim = [0 100];
        ylim = 0;
        filter = 1;
        HP_sp = [0 0 0 0 0 0];    # Filter-Speicher
        NO_sp = [0 0 0 0 0 0];    # Filter-Speicher
        TP_sp = [0 0 0 0 0 0];    # Filter-Speicher
        DQ_sp = [0 0 0 0 0 0];    # Differenzenquotient
        DQ2_sp = [0 0 0 0 0 0];    # Differenzenquotient
    endproperties
    methods (Access=public)
        function obj = dataStreamClass(name,plcolor,plot,filter)
            obj.name    = name;
            obj.plcolor = plcolor;
            obj.plot    = plot;
            obj.filter  = filter;
        endfunction

        function addSample(obj,sample)
          obj.array(obj.ar_index)=sample;
          obj.ar_index = obj.ar_index + 1;
          disp(obj.ar_index);
          disp(obj.array);
        endfunction

        function disp(obj)
            disp("dataStreamClass");
            disp(obj.name);
        endfunction
    endmethods
end

