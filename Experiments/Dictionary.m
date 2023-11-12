clc

names = {};
names(1) = 'EKG';
names(2) = 'SIM';
names(3) = 'PUL';

namelist = {};

##for i = 1:length(names)
##   namelist = [namelist names(i)];
##endfor

##for item = names
##   namelist = [namelist item];
##endfor

disp(namelist)

namelist = {};

##for item = names
##  namelist{end+1} = item{1};
##endfor

for item = names, namelist{end+1} = item{1}; endfor

disp(namelist)

values = 1:numel(namelist);

dict = containers.Map (namelist,values);
a = dict('EKG')
typeinfo(a)
class(a)
b = dict('PUL')
typeinfo(b)
class(b)
c = dict('SIM')
typeinfo(c)
class(c)

