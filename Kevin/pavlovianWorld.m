function pavlovianWorld(t, evts, p, vs, in, out, ~)
%% pavlovianWorld
% Presents a stimulus with random timing, presents a reward a short time
% later. In this version, there are N trials each of aquisition,
% extinction, reaquisition

%% parameters
rewardKey = p.rewardKey.at(evts.expStart); % get value of rewardKey at experiemnt start, otherwise it will take the same value each new trial
rewardKeyPressed = in.keyboard.strcmp(rewardKey); % true each time the reward key is pressed
rewardProbs = p.rewardProbs;

%% Deal with reward availability and block switching
block = t.Node.Net.origin('block');

blockFlipProb = p.blockFlipProb;
new_block = blockFlipProb.at(evts.newTrial).map(@(x) rand < x);

blockTemp = block.at(new_block).map(@(x) ~x);
t.Node.Listeners = [t.Node.Listeners, into(blockTemp, block)];

%% Define timing
iti_trial = p.iti.map(@timeSampler).at(evts.newTrial);
stim_dur_trial = p.stim_dur.map(@timeSampler).at(evts.newTrial);
rewardProb = rewardProbs(block+1);

stimulusOn = evts.newTrial.delay(iti_trial);
stimulusOff = stimulusOn.delay(stim_dur_trial);
rewardTime = stimulusOff.delay(p.trace);

rewardOn = rewardProb.at(rewardTime).map(@(x) rand < x);
%% Define stimulus
stimFlicker = mod(t * p.stimFlickerFrequency, 1) > 0.5;

stimulus = vis.patch(t, 'rect');
stimulus.azimuth = 0;
stimulus.colour = [0, 0, 0];
stimulus.dims = ones(1,2)*p.stimulusSize;

stimulus.show = stimulusOn.to(stimulusOff) & stimFlicker;
vs.stimulus = stimulus;

%% Define reward

reward = merge(rewardKeyPressed, rewardOn > 0);
out.reward = p.rewardSize.at(reward); % output this signal to the reward controller


% Start the first block
block.post(1);

%% End trial and log events
evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.rewardTime = rewardTime;
evts.rewardOn = rewardOn;
evts.block = block;
evts.rewardProb = rewardProb;
% Accumulate reward signals and append microlitre units
evts.totalRewardVolume = out.reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));
% Trial ends when evts.endTrial updates.
evts.endTrial = stimulusOff.delay(0.1);

%% Parameter defaults
% See timeSampler for full details on what values the *Delay paramters can
% take.  Conditional perameters are defined as having ncols > 1, where each
% column is a condition.  All conditional paramters must have the same
% number of columns.
try
    p.rewardProbs = [0.1; 0.9];
    p.iti = [1; 60; 10];
    p.stim_dur = 1;
    p.trace = 0.1;
    p.stimulusSize = 50;
    p.blockFlipProb = 0.02;
    p.stimFlickerFrequency = 5;
    p.rewardSize = 3;
    p.rewardKey = 'r';
    p.aquisitionTrials = 100;
    p.extinctionTrials = 100;
    p.reaquisitionTrials = 100;
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