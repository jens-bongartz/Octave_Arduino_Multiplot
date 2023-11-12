                # Detectoren laufen nur auf dataStream(1)
                if (j == 1)  && (x_index > 2) # nur dataStream(1)
                  # Slope-Detection
                  if (slopeDetect)
                     slopeAct = sign(dataStream(1).array(x_index)-dataStream(1).array(x_index-1));
                     if (slopeAct ~= slopeOld)
                       if (slopeAct < slopeOld) # Ubergang 1 >> -1 = Maximum
                         outBPM = round(60/((x_index-slopeMax)*(1/f_oct)));
                         slopeMax = x_index;
                         #irAC  = dataStream(1).array(slopeMax)-dataStream(1).array(slopeMin)
                         #redAC = dataStream(2).array(slopeMax-1)-dataStream(2).array(slopeMin)
                       else                     # Minimum
                         slopeMin = x_index;
                       endif
                       slopeOld = slopeAct;
                     endif
                  endif
                  # Peak-Detection
                  if (peakDetect)
                    if ((dataStream(1).array(x_index) > peakThreshold) && !peakTrigger)
                      # Doppel-Peaks unterdruecken
                      if (x_index - peakOld) > (f_abtast / 10)
                         peakIntervall = x_index - peakOld;
                         peakOld = x_index;
                         outBPM = round(60/(peakIntervall*(1/f_oct)));
                         peakTrigger = 1;
                      endif
                    endif
                    if ((dataStream(1).array(x_index) < peakThreshold) && peakTrigger)
                      peakTrigger = 0;
                    endif
                  endif
                endif

