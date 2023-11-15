# Filterimplementierung
function [adc,sp] = digitalerFilter(adc,sp,ko);

     sp(3) = sp(2); sp(2) = sp(1); sp(1) = adc; sp(6) = sp(5) ; sp(5) = sp(4);

     sp(4) = sp(1)*ko(1)+sp(2)*ko(2)+sp(3)*ko(3)-sp(5)*ko(4)-sp(6)*ko(5);

     adc   = sp(4);

endfunction
