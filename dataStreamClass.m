% dataStreamClass.m
classdef dataStreamClass
    properties
        name = "";
        array = [ ];
        plot = 1;
        plcolor = "";
        #ylim = [0 100];
        ylim = 0;
        adc_plot = [ ];
        filter = 1;
        HP_sp = [0 0 0 0 0 0];                    % Filter-Speicher
        NO_sp = [0 0 0 0 0 0];                    % Filter-Speicher
        TP_sp = [0 0 0 0 0 0];
    end

    methods
        function obj = dataStreamClass(name,plcolor,plot,filter)
            obj.name    = name;
            obj.plcolor = plcolor;
            obj.plot    = plot;
            obj.filter  = filter;
        endfunction
    end
end

