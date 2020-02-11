function rewardLearningDistractors(t, evts, p, vs, in, out, audio)
%% rewardLearningDistractors
% Reward learning task with visually instructed trials. Reward
% probabilities change unpredictably on both sides and the mouse should
% learn to follow the better side. Also, some trials are instructed-choice,
% where a stimulus appears on one side only, and the mouse must pick it to
% have any shot at reward at all.

%% Static Parameters
rewardSize_leftSpout = p.rewardSize_leftSpout.at(evts.trialNum == 1);
rewardSize_rightSpout = p.rewardSize_rightSpout.at(evts.trialNum == 1);
simultaneous_rewards = p.delay_leftSpout.at(evts.trialNum == 1) == p.delay_rightSpout.at(evts.trialNum == 1);
buffer_size = p.buffer_size.at(evts.trialNum == 1);

%% Input parameters
wheel = p.wheelGain * in.wheelMM.skipRepeats(); % skipRepeats means that this signal doesn't update if the new value is the same of the previous one (i.e. if the wheel doesn't move)

rewardKeyLeft = p.rewardKeyLeft.at(evts.expStart); % get value of rewardKey at experiemnt start, otherwise it will take the same value each new trial
rewardKeyLeftPressed = in.keyboard.strcmp(rewardKeyLeft); % true each time the reward key is pressed

rewardKeyRight = p.rewardKeyRight.at(evts.expStart); 
rewardKeyRightPressed = in.keyboard.strcmp(rewardKeyRight); 

rewardKeyBoth = p.rewardKeyBoth.at(evts.expStart); 
rewardKeyBothPressed = in.keyboard.strcmp(rewardKeyBoth); 

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

%% define response and response threshold
% decide if this should be a free choice trial
free_choice = p.p_free.at(evts.newTrial).map(@(x) rand < x);
% if instructed, decide which side to instruct
ins_side = p.p_left.at(evts.newTrial).map(@(x) rand < x);

leftAvailable = free_choice | ins_side;
rightAvailable = free_choice | ~ins_side;

%% wheel position to stimulus displacement
 laggedWheel = wheel.scan(@(old, new) [new, old(1)], [0,0]); 
 wheel_delta = laggedWheel.map(@(x) x(1) - x(2));
 % Modify the wheel delta on instructed trials -- multiply by
 % p.wheel_gain_asymmetry if the mouse is moving the wrong way
% wheel_delta_locked = cond(~leftAvailable, wheel_delta.map(@(x) min(x, p.wheel_gain_asymmetry*x)), ...
%                           ~rightAvailable, wheel_delta.map(@(x) max(x, p.wheel_gain_asymmetry*x)), ...
%                           leftAvailable & rightAvailable, wheel_delta);
 wheel_delta_locked = cond(~leftAvailable,  mapn(wheel_delta, p.wheel_gain_asymmetry, @(x,g) min(x, g*x)), ...
                           ~rightAvailable, mapn(wheel_delta, p.wheel_gain_asymmetry, @(x,g) max(x, g*x)), ...
                           leftAvailable & rightAvailable, wheel_delta);

% % Enforce borders -- don't let the wheel move past the border
 stimulusDisplacement = wheel_delta_locked.scan(@(curr, delta, border) max(min(curr + delta, border), -1*border), ...
     interactiveOn.map(0), 'pars', p.border);


%% Determine choice
choseLeft = leftAvailable & stimulusDisplacement > p.stimulusAzimuth;
choseRight = rightAvailable & stimulusDisplacement < -1*p.stimulusAzimuth;

choiceMade = interactiveOn.setTrigger(choseLeft | choseRight);

response = -sign(stimulusDisplacement);
response = response.at(choiceMade); % only update the response signal when the threshold has been crossed

%% Deal with reward availability and block switching
block = t.Node.Net.origin('block');
blockFlipProb = t.Node.Net.origin('blockFlipProb');

new_block = blockFlipProb.at(evts.newTrial).map(@(x) rand < x);

blockTemp = block.at(new_block).map(@(x) ~x);
t.Node.Listeners = [t.Node.Listeners, into(blockTemp, block)];

%% define stimuli and reward contingencies
% Pick a reward probability. Based on params for left/right choice,
% left/right spout. the variable "block" flips between 0 and 1
rewardProb_leftChoice_leftSpout = cond(leftAvailable, p.rewardProbs_leftChoice_leftSpout(block + 1), ...
                                       ~leftAvailable, 0);
rewardProb_rightChoice_leftSpout = cond(rightAvailable, p.rewardProbs_rightChoice_leftSpout(block + 1), ...
                                        ~rightAvailable, 0);
rewardProb_leftChoice_rightSpout = cond(leftAvailable, p.rewardProbs_leftChoice_rightSpout(block + 1), ...
                                       ~leftAvailable, 0);
rewardProb_rightChoice_rightSpout = cond(rightAvailable, p.rewardProbs_rightChoice_rightSpout(block + 1), ...
                                        ~rightAvailable, 0);
% Convert this into baiting                                    
baiting_leftChoice_leftSpout   = rewardProb_leftChoice_leftSpout.map(@(x) rand < x);
baiting_rightChoice_leftSpout  = rewardProb_rightChoice_leftSpout.map(@(x) rand < x);
baiting_leftChoice_rightSpout  = rewardProb_leftChoice_rightSpout.map(@(x) rand < x);
baiting_rightChoice_rightSpout = rewardProb_rightChoice_rightSpout.map(@(x) rand < x);

% Convert this into reward and reward time
reward_leftSpout_val = rewardSize_leftSpout * ... 
    ((response == -1 & baiting_leftChoice_leftSpout) | ...
    (response == 1 & baiting_rightChoice_leftSpout));
reward_leftSpout = reward_leftSpout_val.at(choiceMade).delay(p.delay_leftSpout);

reward_rightSpout_val = rewardSize_rightSpout * ...
    ((response == -1 & baiting_leftChoice_rightSpout) | ...
    (response == 1 & baiting_rightChoice_rightSpout));
reward_rightSpout = reward_rightSpout_val.at(choiceMade).delay(p.delay_rightSpout);

% Define a "both" that delivers both simultaneously
both_val = reward_leftSpout * [1,0] + reward_rightSpout * [0,1];
both = both_val.at(choiceMade.delay(p.delay_leftSpout));

% Decide whether to use the "both" or the individual rewards
reward_from_task = iff(simultaneous_rewards, ...
                       both, ...  
                       merge(reward_leftSpout * [1,0], reward_rightSpout * [0,1]));
% Compute reward from keyboard
reward_from_keyboard = 3 * cond(rewardKeyLeftPressed, [1,0], ...
    rewardKeyRightPressed, [0,1],...
    rewardKeyBothPressed, [1,1]);

% The RewardValveController object expects a 2x1 matrix with volume (in uL)
% of reward to put out on each spout
reward_output = merge(reward_from_task, reward_from_keyboard);
total_reward_trial = reward_output.map(@sum);
out.reward = reward_output;

%% Stimulus azimuth
% Stim stays on until the end of the ITI
stimulusOff = choiceMade.delay(p.iti);

azimuth = cond(...
    stimulusOn.to(interactiveOn), 0,... % Before the closed-loop condition, the stimulus is at it's starting azimuth
    interactiveOn.to(choiceMade), stimulusDisplacement,... % Closed-loop condition, where the azimuth yoked to the wheel
    choiceMade.to(stimulusOff),  -response*abs(p.stimulusAzimuth)); % Once threshold is reached the stimulus is fixed again

%% Define stimulus

stimFlicker = mod(t * p.stimFlickerFrequency, 1) < 0.5;

stimL = vis.grating(t, 'sine', 'gaussian');
stimL.sigma = p.sigma;
stimL.spatialFreq = p.spatialFreq;
stimL.phase = 2*pi*evts.newTrial.map(@(v)rand);
stimL.azimuth = azimuth - p.stimulusAzimuth; % negative azimuth makes it a left stimulus
stimL.orientation = p.visOrientation;
stimL.contrast = 1;
stimL.show = leftAvailable & stimulusOn.to(stimulusOff) & stimFlicker;
vs.stimL = stimL;

stimR = vis.grating(t, 'sine', 'gaussian');
stimR.sigma = p.sigma;
stimR.spatialFreq = p.spatialFreq;
stimR.phase = 2*pi*evts.newTrial.map(@(v)rand);
stimR.azimuth = azimuth + p.stimulusAzimuth; % positive azimuth makes it a right stimulus
stimR.orientation = -1*p.visOrientation;
stimR.contrast = 1;
stimR.show = rightAvailable & stimulusOn.to(stimulusOff) & stimFlicker;
vs.stimR = stimR;

%% Performance tracking

% Determine whether the mouse made the better choice
better_choice = iff(rewardProb_leftChoice_leftSpout + rewardProb_leftChoice_rightSpout > rewardProb_rightChoice_leftSpout + rewardProb_rightChoice_rightSpout, ...
                    response == -1, ...
                    response == 1);
better_choice = better_choice.at(free_choice & choiceMade);

% Grow this into a history
% Whenever better_choice updates, it adds itself to the buffer up to 50
% trials
% Whenever block updates, it resets the buffer to all 0s
better_choices_buffer = better_choice.scan(@(old, new) [new, old(1:end-1)], block * buffer_size.map(@(x) zeros(1,x))); 
block_performance =  better_choices_buffer.map(@mean);
blockFlipProb_temp = iff(block_performance > p.performance_threshold, p.blockFlipProb, 0);
t.Node.Listeners = [t.Node.Listeners, into(blockFlipProb_temp, blockFlipProb)];

%% Start the first block
block.post(rand < 0.5);
blockFlipProb.post(0);

%% End trial and log events
% we want to save these signals so we put them in events with appropriate
% names:
evts.rewardProbs_rightChoice_rightSpout = rewardProb_rightChoice_rightSpout;
evts.rewardProbs_leftChoice_rightSpout = rewardProb_leftChoice_rightSpout;
evts.rewardProbs_rightChoice_leftSpout = rewardProb_rightChoice_leftSpout;
evts.rewardProbs_leftChoice_leftSpout = rewardProb_leftChoice_leftSpout;
evts.leftAvailable = leftAvailable;
evts.rightAvailable = rightAvailable;
evts.azimuth = azimuth;
evts.response = response;
evts.better_choice = better_choice;
evts.block_performance = better_choices_buffer.map(@mean);
evts.blockFlipProb = blockFlipProb;
evts.reward_leftSpout = reward_leftSpout;
evts.reward_rightSpout = reward_rightSpout;
evts.block = block;
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
    p.blockFlipProb = 0.1;
    p.buffer_size = 50;
    p.performance_threshold = 0.8;
    p.p_free = 0.8;
    p.p_left = 0.5;
    p.rewardProbs_leftChoice_leftSpout =   [0.8; 0.2];
    p.rewardProbs_rightChoice_leftSpout =  [0.2; 0.2];
    p.rewardProbs_leftChoice_rightSpout =  [0.5; 0.5];
    p.rewardProbs_rightChoice_rightSpout = [0.5; 0.5];
    p.delay_leftSpout = 0.01; 
    p.delay_rightSpout = 0.01; 
    p.rewardSize_leftSpout = 3;
    p.rewardSize_rightSpout = 3;
    p.onsetToneFrequency = 5000;
    p.interactiveDelay = 0.01;
    p.onsetToneAmplitude = 0.15;
    p.stimulusAzimuth = 35;
    p.border = 45;
    p.wheel_gain_asymmetry = 0;
    p.stimFlickerFrequency = 8;
    p.visOrientation = 45;
    p.spatialFreq = 1/10;
    p.sigma = [7,7]';
    p.rewardSize = 2.5;
    p.rewardSizeSmall = 1;
    p.rewardKeyLeft = 'a';
    p.rewardKeyRight = 'd';
    p.rewardKeyBoth = 's';
    p.iti = 1;
    p.wheelGain = 3;
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