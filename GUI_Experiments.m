clc
screensize = get(groot,'screensize')
fi=figure(1,'visible','off');
#fi=figure(1);
#get(fi)

set(fi,'position', [1 1 screensize(3) screensize(4)],'resize','off');
#set(fi,'windowstate','fullscreen');
clf
pl=subplot(2,1,1);
set(pl,'box','on');
set(pl,'units','pixels');
disp('position pl');
pos = get(pl,'position')
li1=line(pl);

##pl2=subplot(2,1,2);
##set(pl2,'box','on');
##set(pl2,'units','pixels');
##disp('position pl2');
##pos2 = get(pl2,'position')
li2=line(pl);

set(fi,'visible','on');
t=-3:0.01:3;
s=3*cos(2*pi*2*t);
set(li1,"xdata",t,"ydata",s);
set(li2,"xdata",s,"ydata",t);

cap_w = 40;
cap_h = 40;
cap_x = (pos(1)-cap_w)/2
cap_y = pos(3)/2

cap = uicontrol(fi,"style","text","string","BPM");
set(cap,"position",[cap_x,cap_y,cap_w,cap_h]);
set(cap,"fontsize",20);

