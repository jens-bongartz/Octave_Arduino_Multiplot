close all;

fi = figure(1)

subPl_one = subplot(2,1,1);
subLi(1) = line(subPl_one);

subPl_two = subplot(2,1,2);
subLi(2) = line(subPl_two);

t=0:0.001:10;
t(1:length(t)/4)=0;
s=5*sin(2*pi*2*t);

set(subPl_one,'box','on','units','pixels');
set(subPl_two,'box','on','units','pixels');

set(subLi(1),"xdata",t,"ydata",s);
set(subPl_one,"xlim",[0 2])

set(subLi(2),"xdata",t,"ydata",s);
set(subPl_two,"xlim",[0 10])

legend(subPl_one,"string","12345");
legend(subPl_two,"string","Hallo");





