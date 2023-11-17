classdef plotGraphClass < handle

  properties
    fi_1 = 0;
    subPl = [];
    subLi = [];
  endproperties

  methods
    function self = plotGraphClass(dataStream)    # Constructor
      self.fi_1 = figure(1);
      clf
      spN = 0;
      for i = 1:length(dataStream);
        if (dataStream(i).plot == 1)
          spN = spN + 1;
        endif
      endfor
      j=0;
      for i = 1:length(dataStream)
        if (dataStream(i).plot == 1)
          j=j+1;
          ## The function subplot returns a handle pointing to an object of type axes.
          self.subPl(j) = subplot(spN,1,j);
          set(self.subPl(j),"box","on","title",dataStream(i).name,"xlim",[0 dataStream(i).plotwidth*dataStream(i).dt]);
          # wenn ylim Grenzen nutzt
          if (sum(dataStream(j).ylim != 0))
            set(self.subPl(j),"ylim",dataStream(i).ylim);
          endif
          # Zeichenfarbe setzen
          self.subLi(j) = line("linewidth",2,"color",dataStream(i).plcolor);
        endif
      endfor
    endfunction

    function draw(self,dataStream)
      j=0;  # iteriert ueber die subPlot-Instanzen
      for i = 1:length(dataStream);
        # wenn plot == 1 dann wird das array des dataStream geplottet >> adc_plot
        if (dataStream(i).plot == 1)
          j=j+1;
##        if (length(dataStream(i).array) > dataStream(i).plotwidth) # Fenster scrollt
          [adc_plot, data_t] = dataStream(i).lastSamples(dataStream(i).plotwidth);
           x_axis = [data_t(1) data_t(end)];
##         else                                                       # Fenster scrollt nicht
##         [adc_plot, data_t] = dataStream(i).lastSamples(dataStream(i).ar_index-1);
##         x_axis = [0 dataStream(i).plotwidth*dataStream(i).dt];
##         endif

           if (ishandle(self.fi_1))
             set(self.subPl(j),"xlim",x_axis);
             set(self.subLi(j),"xdata",data_t,"ydata",adc_plot);
             if (dataStream(i).slopeDetector || dataStream(i).peakDetector)
               titleText = strcat("BPM:",num2str(dataStream(i).BPM));
               set(self.subPl(j),"title",titleText,"fontsize",20);
             endif
           endif
         endif # (dataStream(i).plot==1)
       endfor
    endfunction

  endmethods
end
