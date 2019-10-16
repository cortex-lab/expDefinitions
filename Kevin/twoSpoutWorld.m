function twoSpoutWorld(t, evts, p, vs, in, out, ~)
%% pavlovianWorld
% Presents a stimulus with random timing, presents a reward a short time
% later.


%% Static Parameters
rewardSize = p.rewardSize.at(evts.trialNum == 1);

%% Keyboard inputs
rewardKeyLeft = p.rewardKeyLeft.at(evts.expStart); % get value of rewardKey at experiemnt start, otherwise it will take the same value each new trial
rewardKeyLeftPressed = in.keyboard.strcmp(rewardKeyLeft); % true each time the reward key is pressed

rewardKeyRight = p.rewardKeyRight.at(evts.expStart); 
rewardKeyRightPressed = in.keyboard.strcmp(rewardKeyRight); 

rewardKeyBoth = p.rewardKeyBoth.at(evts.expStart); 
rewardKeyBothPressed = in.keyboard.strcmp(rewardKeyBoth); 

%% Define blocks
%% Deal with reward availability and block switching
blockL = t.Node.Net.origin('blockL');
blockR = t.Node.Net.origin('blockR');

blockFlipProb = p.blockFlipProb;
new_blockL = blockFlipProb.at(evts.newTrial).map(@(x) rand < x);
new_blockR = blockFlipProb.at(evts.newTrial).map(@(x) rand < x);

blockTempL = blockL.at(new_blockL).map(@(x) ~x);
blockTempR = blockR.at(new_blockR).map(@(x) ~x);

t.Node.Listeners = [t.Node.Listeners, into(blockTempL, blockL)];
t.Node.Listeners = [t.Node.Listeners, into(blockTempR, blockR)];

%% Define timing
iti_trial = p.iti.map(@timeSampler).at(evts.newTrial);
stim_dur_trial = p.stim_dur.map(@timeSampler).at(evts.newTrial);

stimulusOn = evts.newTrial.delay(iti_trial);
stimulusOff = stimulusOn.delay(stim_dur_trial);
rewardTime = stimulusOff.delay(p.trace);


%% Define side
stimSide = evts.newTrial.map(@(x) rand() > 0.5);

stimLeft  = iff(stimSide, 1, 0);
stimRight = iff(stimSide, 0, 1);
               
%% Define stimulus
stimFlicker = mod(t * p.stimFlickerFrequency, 1) > 0.5;

stimulusL = vis.patch(t, 'rect');
stimulusL.azimuth =  -1 * p.stimulusAzimuth;
stimulusL.colour = [0, 0, 0];
stimulusL.dims = ones(1,2)*p.stimulusSize;
stimulusL.show = stimulusOn.to(stimulusOff) & stimFlicker & stimLeft;

stimulusR = vis.patch(t, 'rect');
stimulusR.azimuth =  p.stimulusAzimuth;
stimulusR.colour = [0, 0, 0];
stimulusR.dims = ones(1,2)*p.stimulusSize;
stimulusR.show = stimulusOn.to(stimulusOff) & stimFlicker & stimRight;


vs.stimulusR = stimulusR; 
vs.stimulusL = stimulusL; 

%% Define reward
rewardProbLeft = p.rewardProbs(blockL + 1);
rewardProbRight = p.rewardProbs(blockR + 1);

leftBaited  = iff(stimLeft, ...
    rewardProbLeft.at(evts.newTrial).map(@(x) rand < x), ...
    0);

rightBaited = iff(stimRight, ...
    rewardProbRight.at(evts.newTrial).map(@(x) rand < x), ...
    0);

task_baiting = cond( ~leftBaited & ~rightBaited, [0,0], ...
    leftBaited & ~rightBaited, [1,0], ...
    ~leftBaited & rightBaited, [0,1],...
    leftBaited & rightBaited, [1,1]);

reward_from_task = task_baiting.at(rewardTime);

%% Define reward output
reward_from_keyboard = cond(rewardKeyLeftPressed, [1,0], ...
    rewardKeyRightPressed, [0,1],...
    rewardKeyBothPressed, [1,1]);

% The RewardValveController object expects a 2x1 matrix with volume (in uL)
% of reward to put out on each spout
reward_output = rewardSize * merge(reward_from_task, reward_from_keyboard);
total_reward_trial = reward_output.map(@sum);
out.reward = reward_output;

% Start the first block
blockL.post(1);
blockR.post(1);

%% End trial and log events
evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.rewardTime = rewardTime;
evts.task_baiting = task_baiting;
evts.reward_output = reward_output;
evts.rewardProbLeft = rewardProbLeft;
evts.rewardProbRight = rewardProbRight;
evts.trialReward = total_reward_trial;
evts.rewardLeft = leftBaited;
evts.rewardRight = rightBaited;
% Accumulate reward signals and append microlitre units
evts.totalRewardVolume = total_reward_trial.scan(@plus, 0);
evts.totalRewardMicroliters = evts.totalRewardVolume.map(fun.partial(@sprintf, '%.1fµl'));
% Trial ends when evts.endTrial updates.
evts.endTrial = stimulusOff.delay(0.01);

%% Parameter defaults
% See timeSampler for full details on what values the *Delay paramters can
% take.  Conditional perameters are defined as having ncols > 1, where each
% column is a condition.  All conditional paramters must have the same
% number of columns.
try
    p.rewardProbs = [0.1; 0.9];
    p.iti = [1; 60; 15];
    p.stim_dur = 1;
    p.trace = 0.1;
    p.stimulusAzimuth = 35;
    p.stimulusSize = 50;
    p.blockFlipProb = 0.02;
    p.stimFlickerFrequency = 8;
    p.rewardSize = 2;
    p.rewardKeyLeft = 'a';
    p.rewardKeyBoth = 's';
    p.rewardKeyRight = 'd';
    p.pLeft = 1/3;
    p.pRight = 1/3;
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