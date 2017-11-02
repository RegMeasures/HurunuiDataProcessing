function [] = subplot_ts(ax,idx,ytix,lbl,spacing,offset,varargin)
%%% Stacked Time Series Subplotter %%%

%%Author: A. Seltzer

%%Version: 1.01

%%Description: Plots up to 4 series on one y-axis. Designed to accomodate
%%infinite axes stacked atop one another with appropriate amount of white
%%space in between.

%%Inputs:
%   ax: axes array generated by nice_ts_figure function call
%   idx: index of this particular axis
%   ytix: array of y tick marks (in ascending order indicates regular y
%         axis; in decending order indicates reversed y axis)
%   lbl: ylabel text
%   spacing: 0 = each axes uses whole range (no spacing)
%            1 = each axes uses half of range
%            0.5 = each axes uses 75% of range
%   varargin: add up to FOUR time series to plot by passing 's1' (for
%              series #1, 's2' for #2, etc.), followed by regular plotting
%              parameters passed to plot.m function call. (see example)
%   offset: vertically shift the subplot. +ve upwards, -ve downwards
%           generally values in the range -3 to +3 are appropriate


%%Usage: pass axes index number, vector of y tick values, then series to
%%plot (4 max) using usual plot command after idenfying series with 's1'
%%for s1.

%%Example: see example_ts file.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if idx>1
    oldytix=get(gca,'ytick');
    oldyticklabs=str2num(get(gca,'yticklabels'));
end
s1ind=0;s2ind=0;s3ind=0;s4ind=0;
for i=1:length(varargin)
    if ischar(varargin{i})
        if strcmp(varargin{i},'s1')
            s1ind=i;
        elseif strcmp(varargin{i},'s2')
            s2ind=i;
        elseif strcmp(varargin{i},'s3')
            s3ind=i;
        elseif strcmp(varargin{i},'s4')
            s4ind=i;
        end
    end
end

%%ID 1st series
if s2ind==0
    s1end=length(varargin);
else
    s1end=s2ind-1;
end
xlims=get(gca,'xlim');
x1=varargin{s1ind+1};
y1=varargin{s1ind+2};
y1=y1(and(x1>=xlims(1),x1<=xlims(2)));
x1=x1(and(x1>=xlims(1),x1<=xlims(2)));
maxs(1)=max(y1);
mins(1)=min(y1);

%%ID 2nd series
if s2ind~=0
    if s3ind==0
        s2end=length(varargin);
    else
        s2end=s3ind-1;
    end
    x2=varargin{s1ind+1};
    y2=varargin{s1ind+2};
    y2=y2(and(x2>=xlims(1),x2<=xlims(2)));
    x2=x2(and(x2>=xlims(1),x2<=xlims(2)));
    maxs(1)=max(y2);
    mins(1)=min(y2);
end

%%ID 3rd series
if s3ind~=0
    if s4ind==0
        s3end=length(varargin);
    else
        s3end=s4ind-1;
    end
    x3=varargin{s1ind+1};
    y3=varargin{s1ind+2};
    y3=y3(and(x3>=xlims(1),x3<=xlims(2)));
    x3=x3(and(x3>=xlims(1),x3<=xlims(2)));
    maxs(1)=max(y3);
    mins(1)=min(y3);
end

%%ID 4th series
if s4ind~=0
        s4end=length(varargin);
    x4=varargin{s1ind+1};
    y4=varargin{s1ind+2};
    y4=y4(and(x4>=xlims(1),x4<=xlims(2)));
    x4=x4(and(x4>=xlims(1),x4<=xlims(2)));
    maxs(1)=max(y4);
    mins(1)=min(y4);
end

%%Scaling
rangeFill=5*(1-spacing)+5;
range=abs(max(maxs)-min(mins));
scale=rangeFill/range;
isRev=ytix(1)>ytix(2);
if(isRev)
    flipscale=-1*scale;
else
    flipscale=1*scale;
end
mdp=(min(mins)+range/2)*flipscale; %mid point of range


varargin{s1ind+2}=varargin{s1ind+2}.*flipscale-10*idx-mdp+5+offset;
if s2ind~=0
    varargin{s2ind+2}=varargin{s2ind+2}.*flipscale-10*idx-mdp+5+offset;
end
if s3ind~=0
    varargin{s3ind+2}=varargin{s3ind+2}.*flipscale-10*idx-mdp+5+offset;
end
if s4ind~=0
    varargin{s4ind+2}=varargin{s4ind+2}.*flipscale-10*idx-mdp+5+offset;
end

%%Plot series
axes(ax(idx+1)); %set to correct axes
hold on;
plot(varargin{s1ind+1:s1end});
if(s2ind~=0)
    plot(varargin{s2ind+1:s2end});
end
if(s3ind~=0)
    plot(varargin{s3ind+1:s3end});
end
if(s4ind~=0)
    plot(varargin{s4ind+1:s4end});
end

%%Set tick marks
set(gca,'ytick',ytix.*flipscale-10*idx-mdp+5,'yticklabels',ytix);

%%Print label
dir=get(gca,'xdir');
xmax=max(get(gca,'xlim'));
xmin=min(get(gca,'xlim'));
if mod(idx,2)==1
    if strcmp(dir,'reverse')
        xpt=1.075*(xmax-xmin)+xmin;
    else
        xpt=xmax-1.075*(xmax-xmin);
    end
else
    if strcmp(dir,'reverse')
        xpt=xmax-1.075*(xmax-xmin);
    else
        xpt=1.075*(xmax-xmin)+xmin;
    end
end
ypt=-10*idx+5;
ylabel(lbl,'position',[xpt ypt]);


end




