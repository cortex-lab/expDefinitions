function twoSpoutDebug(t, evts, p, vs, in, out, ~)
%% pavlovianWorld
% Presents a stimulus with random timing, presents a reward a short time
% later. In this version, there are N trials each of aquisition,
% extinction, reaquisition

%% parameters
rewardKeyLeft = p.rewardKeyLeft.at(evts.expStart); % get value of rewardKey at experiemnt start, otherwise it will take the same value each new trial
rewardKeyLeftPressed = in.keyboard.strcmp(rewardKeyLeft); % true each time the reward key is pressed

rewardKeyRight = p.rewardKeyRight.at(evts.expStart); 
rewardKeyRightPressed = in.keyboard.strcmp(rewardKeyRight); 

rewardKeyBoth = p.rewardKeyBoth.at(evts.expStart); 
rewardKeyBothPressed = in.keyboard.strcmp(rewardKeyBoth); 


%% Define reward

reward = cond(rewardKeyLeftPressed, [1,0], ...
              rewardKeyRightPressed, [0,1],...
              rewardKeyBothPressed, [1,1]);

out.rewardValves = p.rewardSize.at(reward); % output this signal to the reward controller

% Start the first block
block.post(1);

%% End trial and log events
evts.lickLeft = in.lick;
evts.lickRight = in.lick2;

%% Parameter defaults
% See timeSampler for full details on what values the *Delay paramters can
% take.  Conditional perameters are defined as having ncols > 1, where each
% column is a condition.  All conditional paramters must have the same
% number of columns.
try
    p.rewardSize = 3;
    p.rewardKeyLeft = 'q';
    p.rewardKeyRight = 'w';
    p.rewardKeyBoth = 'e';
catch % ex
    %    disp(getReport(ex, 'extended', 'hyperlinks', 'on'))
end

%% Helper functions
    function duration = timeSampler(time)
        % TIMESAMPLER Sample a time from some distribution
        %  If time is a single value, duration is that value.  If time = [min max],
        %  then duration is sampled uniformally.  If time = [min, max, time const],
        %  then duration is sampled from a exponential distribution, giving a flat
        %  hazard rate.  If numel(time) > 3, duration is a randomly sampled value
        %  from time.
        %
        % See also exp.TimeSampler
        if nargin == 0; duration = 0; return; end
        switch length(time)
            case 3 % A time sampled with a flat hazard function
                duration = time(1) + exprnd(time(3));
                duration = iff(duration > time(2), time(2), duration);
            case 2 % A time sampled from a uniform distribution
                duration = time(1) + (time(2) - time(1))*rand;
            case 1 % A fixed time
                duration = time(1);
            otherwise % Pick on of the values
                duration = randsample(time, 1);
        end
    end
end