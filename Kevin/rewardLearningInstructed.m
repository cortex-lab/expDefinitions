function rewardLearningInstructed(t, evts, p, vs, in, out, audio)
%% rewardLearningInstructed
% Reward learning task with visually instructed trials. Reward
% probabilities change unpredictably on both sides and the mouse should
% learn to follow the better side. Also, some trials are instructed-choice,
% where a stimulus appears on one side only, and the mouse must pick it to
% have any shot at reward at all.


%% Input parameters
wheel = in.wheelMM.skipRepeats(); % skipRepeats means that this signal doesn't update if the new value is the same of the previous one (i.e. if the wheel doesn't move)
rewardKey = p.rewardKey.at(evts.expStart); % get value of rewardKey at experiemnt start, otherwise it will take the same value each new trial
rewardKeyPressed = in.keyboard.strcmp(rewardKey); % true each time the reward key is pressed

%% when to present stimuli & allow visual stim to move
% stimulus should come on after the wheel has been held still for the
% duration of the preStimulusDelay.  

preStimulusDelay = p.preStimulusDelay.map(@timeSampler).at(evts.newTrial); % at(evts.newTrial) fix for rig pre-delay
preStimQuiescence = sig.quiescenceWatch(preStimulusDelay, t, wheel, 0.5); % 0.5mm is movement threshold
stimulusOn = at(true, preStimQuiescence);
interactiveDelay = p.interactiveDelay.map(@timeSampler);
interactiveOn = stimulusOn.delay(interactiveDelay); % the closed-loop period starts when the stimulus comes on, plus an 'interactive delay'

audioDevice = audio.Devices('default');
onsetToneSamples = p.onsetToneAmplitude*...
    mapn(p.onsetToneFrequency, 0.1, audioDevice.DefaultSampleRate,...
    0.02, audioDevice.NrOutputChannels, @aud.pureTone); % aud.pureTone(freq, duration, samprate, "ramp duration", nAudChannels)
audio.default = onsetToneSamples.at(interactiveOn); % At the time of 'interative on', send samples to audio device and log as 'onsetTone'

%% wheel position to stimulus displacement
wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
stimulusDisplacement = p.wheelGain*(wheel - wheelOrigin); % yoke the stimulus displacment to the wheel movement during closed loop

%% define response and response threshold
% decide if this should be a free choice trial
free_choice = p.p_free.at(evts.newTrial).map(@(x) rand < x);
% if instructed, decide which side to instruct
ins_side = p.p_left.at(evts.newTrial).map(@(x) rand < x);

leftAvailable = free_choice | ins_side;
rightAvailable = free_choice | ~ins_side;

choseLeft = leftAvailable & stimulusDisplacement < -1*p.stimulusAzimuth;
choseRight = rightAvailable & stimulusDisplacement > p.stimulusAzimuth;

choiceMade = interactiveOn.setTrigger(merge(choseLeft, choseRight));

response = -sign(stimulusDisplacement);
response = response.at(choiceMade); % only update the response signal when the threshold has been crossed

%% Deal with reward availability and block switching
block = t.Node.Net.origin('block');

blockFlipProb = p.blockFlipProb;
new_block = blockFlipProb.at(evts.newTrial).map(@(x) rand < x);

blockTemp = block.at(new_block).map(@(x) ~x);
t.Node.Listeners = [t.Node.Listeners, into(blockTemp, block)];

%% define stimuli and reward contingencies
% Pick a reward probability. At the moment, this is constant and based on a
% parameter. In other expDefs, it should be somthing smarter
leftRewardProb = cond(leftAvailable & block, p.rewardProb_high, ...
                    leftAvailable & ~block, p.rewardProb_low, ...
                    ~leftAvailable, 0);
rightRewardProb = cond(rightAvailable & ~block, p.rewardProb_high, ...
                    rightAvailable & block, p.rewardProb_low, ...
                    ~rightAvailable, 0);
leftBaited = leftRewardProb.map(@(x) rand < x);
rightBaited = rightRewardProb.map(@(x) rand < x);

leftBaitedSmall = ~leftBaited & leftAvailable;
rightBaitedSmall = ~rightBaited & rightAvailable;

% Determine when the mouse gets a reward
feedback = (response == -1 & leftBaited) | ...
    (response == 1 & rightBaited);
feedback = feedback.at(choiceMade).delay(p.reward_delay);

% Determine when the mouse gets a small reward
feedbackSmall = (response == -1 & leftBaitedSmall) | ...
    (response == 1 & rightBaitedSmall);
feedbackSmall = feedbackSmall.at(threshold).delay(p.reward_delay);

% Determine when the mouse gets a timeout for violation of an instructed
% trial
violation = (response == -1 & ~leftAvailable) | (response == 1 & ~rightAvailable);
violation = violation.at(threshold);

noiseBurstSamples = p.noiseBurstAmp*...
    mapn(audioDevice.NrOutputChannels, p.noiseBurstDur*audioDevice.DefaultSampleRate, @randn);
audio.default = noiseBurstSamples.at(violation==1); % When the subject gives an incorrect response, send samples to audio device and log as 'noiseBurst'

reward = merge(rewardKeyPressed, feedback > 0);% only update when feedback changes to greater than 0, or reward key is pressed
out.reward = merge(p.rewardSize.at(reward), p.rewardSizeSmall.at(feedbackSmall > 0)); % output this signal to the reward controller

%% stimulus azimuth
% ITI defined by outcome
iti = iff(violation, p.itiViolation, p.itiNormal);
feedback_time = feedback + 1; % will always evaluate to true
% Stim stays on until the end of the ITI
stimulusOff = feedback_time.delay(iti);

azimuth = cond(...
    stimulusOn.to(interactiveOn), 0,... % Before the closed-loop condition, the stimulus is at it's starting azimuth
    interactiveOn.to(threshold), stimulusDisplacement,... % Closed-loop condition, where the azimuth yoked to the wheel
    threshold.to(stimulusOff),  -response*abs(p.stimulusAzimuth)); % Once threshold is reached the stimulus is fixed again

%% Define stimulus

stimFlicker = mod(t * p.stimFlickerFrequency, 1) < 0.5;

stimL = vis.grating(t, 'sine', 'gaussian');
stimL.sigma = p.sigma;
stimL.spatialFreq = p.spatialFreq;
stimL.phase = 2*pi*evts.newTrial.map(@(v)rand);
stimL.azimuth = azimuth - p.stimulusAzimuth; % negative azimuth makes it a left stimulus
stimL.contrast = 1;
stimL.show = leftAvailable & stimulusOn.to(stimulusOff) & stimFlicker;
vs.stimL = stimL;


stimR = vis.grating(t, 'sine', 'gaussian');
stimR.sigma = p.sigma;
stimR.spatialFreq = p.spatialFreq;
stimR.phase = 2*pi*evts.newTrial.map(@(v)rand);
stimR.azimuth = azimuth + p.stimulusAzimuth; % positive azimuth makes it a right stimulus
stimR.contrast = 1;
stimR.show = rightAvailable & stimulusOn.to(stimulusOff) & stimFlicker;
vs.stimR = stimR;



%% Track performance

violations_left = violation.keepWhen(~rightAvailable).scan(@plus,0);
violations_right = violation.keepWhen(~leftAvailable).scan(@plus,0);
violations_all = violations_left + violations_right;

nTrials_left = threshold.keepWhen(~rightAvailable).scan(@plus,0);
nTrials_right = threshold.keepWhen(~leftAvailable).scan(@plus,0);

p_correct_all = 1 - violations_all.at(evts.newTrial) / (nTrials_left.at(evts.newTrial) + nTrials_right.at(evts.newTrial));
p_correct_left = 1 - violations_left.at(evts.newTrial) / nTrials_left.at(evts.newTrial);
p_correct_right = 1 - violations_right.at(evts.newTrial) / nTrials_right.at(evts.newTrial);

%% Start the first block
block.post(rand < 0.5);

%% End trial and log events

% we want to save these signals so we put them in events with appropriate
% names:
evts.leftRewardProb = leftRewardProb;
evts.rightRewardProb = rightRewardProb;
evts.leftAvailable = leftAvailable;
evts.rightAvailable = rightAvailable;
evts.azimuth = azimuth;
evts.response = response;
evts.feedback = feedback;
evts.violation = violation;
evts.block = block;
% Accumulate reward signals and append microlitre units
evts.totalRewardVolume = out.reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));
evts.p_correct_left = p_correct_left;
evts.p_correct_right = p_correct_right;
evts.p_correct_all = p_correct_all;
% Trial ends when evts.endTrial updates.
evts.endTrial = stimulusOff.delay(0.01);

%% Parameter defaults
% See timeSampler for full details on what values the *Delay paramters can
% take.  Conditional perameters are defined as having ncols > 1, where each
% column is a condition.  All conditional paramters must have the same
% number of columns.
try
    p.blockFlipProb = 0.02;
    p.p_free = 0.5;
    p.p_left = 0.5;
    p.rewardProb_high = 1;
    p.rewardProb_low = 0.5;
    p.reward_delay = 0.01; 
    p.onsetToneFrequency = 5000;
    p.interactiveDelay = 0.01;
    p.onsetToneAmplitude = 0.15;
    p.stimulusAzimuth = 35;
    p.stimFlickerFrequency = 8;
    p.spatialFreq = 1/10;
    p.sigma = [7,7]';
    p.noiseBurstAmp = 0.01;
    p.noiseBurstDur = 3;
    p.rewardSize = 3;
    p.rewardSizeSmall = 1;
    p.rewardKey = 'r';
    p.itiNormal = 1;
    p.itiViolation = 3;
    p.wheelGain = 2;
    p.preStimulusDelay = [0.2, 0.5, 0.35]'; % Exponentially distributed no-stim ITI
catch
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