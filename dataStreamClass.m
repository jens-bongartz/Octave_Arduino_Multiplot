% dataStreamClass.m >> This is a handle-Class!
classdef dataStreamClass < handle

    properties
        name = "";
        array = [];              # in array[] stehen alle Messdaten seit CLEAR
        t = [];
        dt    = 5;
        t_sum = 0;
        ar_index = 1;
        adc_plot = [];
        plotwidth = 800;
        plot = 1;
        plcolor = "";
        length = 3000;
        ylim = 0;                 #yalternativ lim = [0 100];
        filter = 1;
        HP_sp =  [0 0 0 0 0 0];    # Filter-Speicher
        NO_sp =  [0 0 0 0 0 0];    # Filter-Speicher
        TP_sp =  [0 0 0 0 0 0];    # Filter-Speicher
        DQ_sp =  [0 0 0 0 0 0];    # Differenzenquotient
        DQ2_sp = [0 0 0 0 0 0];   # Differenzenquotient
    endproperties

    methods (Access=public)

        function self = dataStreamClass(name,plcolor,dt,plotwidth,plot,filter)
            self.name      = name;
            self.plcolor   = plcolor;
            self.dt        = dt;
            self.plotwidth = plotwidth;
            self.plot      = plot;
            self.filter    = filter;
        endfunction

        function addSample(self,sample,sample_t)
          self.array(self.ar_index)=sample;
          self.t_sum = self.t_sum + sample_t;
          self.t(self.ar_index) = self.t_sum;

          self.ar_index = self.ar_index + 1;
          if (self.ar_index > self.length)
            self.ar_index = 1;
          endif
        endfunction

        function [ret_array, ret_time] = lastSamples(self,n)
          if (self.ar_index - n > 0)          # kein Wrap-Around notwendig
              ret_array = self.array(self.ar_index-n:self.ar_index-1);
              ret_time  = self.t(self.ar_index-n:self.ar_index-1);
          else                                 # n > ar_index >> Wrap-Around
              n1 = n - self.ar_index;
              ret_array = self.array(self.length-n1:self.length);
              ret_array = [ret_array self.array(1:self.ar_index-1)];
              ret_time = self.t(self.length-n1:self.length);
              ret_time = [ret_time self.t(1:self.ar_index-1)];
          endif
        endfunction

        function clear(self)
          self.ar_index = 1;
          self.array = [];
          self.t = [];
          self.t_sum = 0;
        endfunction

        function disp(self)
            disp("dataStreamClass");
            disp(self.name);
        endfunction
    endmethods
end

