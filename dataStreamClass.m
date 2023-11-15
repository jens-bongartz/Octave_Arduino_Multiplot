% dataStreamClass.m >> This is a handle-Class!
classdef dataStreamClass < handle

    properties
        name = "";
        array = [];              # in array[] stehen alle Messdaten seit CLEAR
        ar_index = 1;
        length = 3000;
        t = [];
        dt    = 5;
        t_sum = 0;
        plotwidth = 800;
        plot = 1;
        plcolor = "";
        ylim = 0;                 #yalternativ lim = [0 100];
        filter = 1;
        HP_sp  = [0 0 0 0 0 0];    # Filter-Speicher
        NO_sp  = [0 0 0 0 0 0];    # Filter-Speicher
        TP_sp  = [0 0 0 0 0 0];    # Filter-Speicher
        DQ_sp  = [0 0 0 0 0 0];    # Differenzenquotient
        DQ2_sp = [0 0 0 0 0 0];    # Differenzenquotient
        HP_ko  = [0 0 0 0 0];
        NO_ko  = [0 0 0 0 0];
        TP_ko  = [0 0 0 0 0];
        DQ_ko  = [0 0 0 0 0];
        DQ2_ko  = [0 0 0 0 0];
        slopeDetector    = 0;
        lastSample       = 0;
        lastSlope        = 1;
        lastMaxTime      = 0;
        peakDetector     = 0;
        peakThreshold    = 0;
        peakTrigger      = 0;
        lastPeakTime     = 0;
        evalCounter      = 0;
        evalWindow       = 200;
        BPM              = 0;
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

        function createFilter(self,f_abtast,f_HP,f_NO,f_TP)
          self.HP_ko = calcHPCoeff(f_abtast,f_HP);
          self.NO_ko = calcNotchCoeff(f_abtast,f_NO);
          self.TP_ko = calcTPCoeff(f_abtast,f_TP);
          self.DQ_ko  = [1 -1 0 0 0];                   # (x[n]-x[n-1])/1
          self.DQ2_ko = [1 0 -1 0 0];                   # (x[n]-x[n-2])/(2) (1)
        endfunction

        function addSample(self,sample,sample_t)

          if (self.filter > 0)
            sample = self.doFilter(sample);
          endif

          if (abs(sample) < 0.0001)        # 'dataaspectratio' Error verhindern
            sample = 0;
          endif

          self.array(self.ar_index)=sample;

          self.t_sum = self.t_sum + sample_t;
          self.t(self.ar_index) = self.t_sum;

          # Ringspeicher Indexing
          self.ar_index = self.ar_index + 1;
          if (self.ar_index > self.length)
            self.ar_index = 1;
          endif

          # Peak-Detector
          if (self.peakDetector)

            self.evalCounter = self.evalCounter + 1;
            # regelmaessig neu Threshold bestimmen
            if (self.evalCounter > self.evalWindow)
              self.evalThreshold;
            endif

            self.peakDetectorFunction(sample);

          endif

          # Slope-Detector
          if (self.slopeDetector)

            self.slopeDetectorFunction(sample);

          endif

          self.lastSample = sample;

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

        function sample = doFilter(self,sample)
          # Statusvariablen ob Filter gesetzt sind
          global HP_filtered NO_filtered TP_filtered DQ_filtered DQ2_filtered;
          #  Am 30.10.2023 Reihenfolge der digitalen Filter verändert
          #  ist: NO > TP > HP
          #  war: HP > NO > TP
          if (NO_filtered)
            [sample,self.NO_sp] = digitalerFilter(sample,self.NO_sp,self.NO_ko);
           endif
           if (TP_filtered)
             [sample,self.TP_sp] = digitalerFilter(sample,self.TP_sp,self.TP_ko);
           endif
           if (HP_filtered)
             [sample,self.HP_sp] = digitalerFilter(sample,self.HP_sp,self.HP_ko);
           endif
           if (DQ_filtered)
             [sample,self.DQ_sp] = digitalerFilter(sample,self.DQ_sp,self.DQ_ko);
           endif
           if (DQ2_filtered)
             [sample,self.DQ2_sp] = digitalerFilter(sample,self.DQ2_sp,self.DQ2_ko);
           endif
        endfunction

        function slopeDetectorFunction(self,sample)
          slope = sign(sample - self.lastSample);
          if (slope ~= self.lastSlope)
            if (slope < self.lastSlope) # Ubergang 1 >> -1 = Maximum
              if (self.t_sum - self.lastMaxTime > 50)
               self.BPM = round(60000 / (self.t_sum - self.lastMaxTime));
               self.lastMaxTime = self.t_sum;
              endif
            endif
          endif
          self.lastSlope  = slope;
        endfunction

        function evalThreshold(self)
          evalArray = self.lastSamples(self.evalWindow);
          if (max(evalArray) > 4*std(evalArray))
             self.peakThreshold = 0.5*max(evalArray);
          endif
          self.evalCounter = 0;
        endfunction

        function peakDetectorFunction(self,sample)
          # und Threshold vergleichen
          if ((sample > self.peakThreshold) && !self.peakTrigger)
            # Doppel-Peaks unterdruecken (50ms)
            if (self.t_sum - self.lastPeakTime > 50)
              self.BPM = round(60000 / (self.t_sum - self.lastPeakTime));
              self.lastPeakTime = self.t_sum;
              self.peakTrigger = 1;
            endif
          endif
          if ((sample < self.peakThreshold) && self.peakTrigger)
            self.peakTrigger = 0;
          endif
        endfunction

        function clear(self)
          self.ar_index     = 1;
          self.array        = [];
          self.t            = [];
          self.t_sum        = 0;
          self.lastMaxTime  = 0;
          self.lastPeakTime = 0;
        endfunction

        function disp(self)
            disp("dataStreamClass");
            disp(self.name);
        endfunction
    endmethods
end

