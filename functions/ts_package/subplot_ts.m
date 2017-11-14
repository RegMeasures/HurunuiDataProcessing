function [H] = subplot_ts(ax,idx,ytix,lbl,Yscale,offset,varargin)
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
%   Yscale: 1 = each axes uses whole range (no spacing)
%           0.5 = each axes uses half of range
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
s1ind=0;s2ind=0;s3ind=0;s4ind=0;s5ind=0;s6ind=0;s7ind=0;s8ind=0;
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
        elseif strcmp(varargin{i},'s5')
            s5ind=i;
        elseif strcmp(varargin{i},'s6')
            s6ind=i;
        elseif strcmp(varargin{i},'s7')
            s7ind=i;
        elseif strcmp(varargin{i},'s8')
            s8ind=i;
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
    x2=varargin{s2ind+1};
    y2=varargin{s2ind+2};
    y2=y2(and(x2>=xlims(1),x2<=xlims(2)));
    x2=x2(and(x2>=xlims(1),x2<=xlims(2)));
    maxs(2)=max(y2);
    mins(2)=min(y2);
end

%%ID 3rd series
if s3ind~=0
    if s4ind==0
        s3end=length(varargin);
    else
        s3end=s4ind-1;
    end
    x3=varargin{s3ind+1};
    y3=varargin{s3ind+2};
    y3=y3(and(x3>=xlims(1),x3<=xlims(2)));
    x3=x3(and(x3>=xlims(1),x3<=xlims(2)));
    maxs(3)=max(y3);
    mins(3)=min(y3);
end

%%ID 4th series
if s4ind~=0
    if s5ind==0
        s4end=length(varargin);
    else
        s4end=s5ind-1;
    end
    x4=varargin{s4ind+1};
    y4=varargin{s4ind+2};
    y4=y4(and(x4>=xlims(1),x4<=xlims(2)));
    x4=x4(and(x4>=xlims(1),x4<=xlims(2)));
    maxs(4)=max(y4);
    mins(4)=min(y4);
end

%%ID 5th series
if s5ind~=0
    if s6ind==0
        s5end=length(varargin);
    else
        s5end=s6ind-1;
    end
    x5=varargin{s5ind+1};
    y5=varargin{s5ind+2};
    y5=y5(and(x5>=xlims(1),x5<=xlims(2)));
    x5=x5(and(x5>=xlims(1),x5<=xlims(2)));
    maxs(5)=max(y5);
    mins(5)=min(y5);
end

%%ID 6th series
if s6ind~=0
    if s5ind==0
        s6end=length(varargin);
    else
        s6end=s7ind-1;
    end
    x6=varargin{s6ind+1};
    y6=varargin{s6ind+2};
    y6=y6(and(x6>=xlims(1),x6<=xlims(2)));
    x6=x6(and(x6>=xlims(1),x6<=xlims(2)));
    maxs(6)=max(y6);
    mins(6)=min(y6);
end

%%ID 7th series
if s7ind~=0
    if s5ind==0
        s7end=length(varargin);
    else
        s7end=s8ind-1;
    end
    x7=varargin{s7ind+1};
    y7=varargin{s7ind+2};
    y7=y7(and(x7>=xlims(1),x7<=xlims(2)));
    x7=x7(and(x7>=xlims(1),x7<=xlims(2)));
    maxs(7)=max(y7);
    mins(7)=min(y7);
end

%%ID 8th series
if s8ind~=0
    s8end=length(varargin);
    x8=varargin{s8ind+1};
    y8=varargin{s8ind+2};
    y8=y8(and(x8>=xlims(1),x8<=xlims(2)));
    x8=x8(and(x8>=xlims(1),x8<=xlims(2)));
    maxs(8)=max(y8);
    mins(8)=min(y8);
end

%%Scaling
rangeFill = 10 * Yscale;
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
if s5ind~=0
    varargin{s5ind+2}=varargin{s5ind+2}.*flipscale-10*idx-mdp+5+offset;
end
if s6ind~=0
    varargin{s6ind+2}=varargin{s6ind+2}.*flipscale-10*idx-mdp+5+offset;
end
if s7ind~=0
    varargin{s7ind+2}=varargin{s7ind+2}.*flipscale-10*idx-mdp+5+offset;
end
if s8ind~=0
    varargin{s8ind+2}=varargin{s8ind+2}.*flipscale-10*idx-mdp+5+offset;
end

%%Plot series
axes(ax(idx+1)); %set to correct axes
hold on;
H{1} = plot(varargin{s1ind+1:s1end});
if(s2ind~=0)
    H{2} = plot(varargin{s2ind+1:s2end});
end
if(s3ind~=0)
    H{3} = plot(varargin{s3ind+1:s3end});
end
if(s4ind~=0)
    H{4} = plot(varargin{s4ind+1:s4end});
end
if(s5ind~=0)
    H{5} = plot(varargin{s5ind+1:s5end});
end
if(s6ind~=0)
    H{6} = plot(varargin{s6ind+1:s6end});
end
if(s7ind~=0)
    H{7} = plot(varargin{s7ind+1:s7end});
end
if(s8ind~=0)
    H{8} = plot(varargin{s8ind+1:s8end});
end

%%Set tick marks
set(gca,'ytick',ytix.*flipscale-10*idx-mdp+5+offset,'yticklabels',ytix);

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
ypt=-10*idx+5+offset;
ylabel(lbl,'position',[xpt ypt]);


end




