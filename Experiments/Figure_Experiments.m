fi = figure(1)
pl = subplot(1,1,1)
li = line(pl)

t=0:0.001:10;
s=5*sin(2*pi*2*t);

set(pl,'box','on');
set(pl,'units','pixels');

set(li,"xdata",t,"ydata",s);
set(pl,"xlim",[0 20])

