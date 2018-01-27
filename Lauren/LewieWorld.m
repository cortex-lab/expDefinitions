function LewieWorld(t, events, parameters, visStim, inputs, outputs, audio)
%% advancedChoiceWorld
% Burgess 2AUFC task with contrast discrimination
% 2017-03-25 Added contrast discrimination MW
% 2017-05-03 Added modifications for blue rigs MW/JL
% 2017-05-05 Added reward tone JL%% Set up wheel 

p = parameters;

%% Fixed parameters

% Reward
rewardSize = 3;

% Stimulus/target
% (which contrasts to use)
contrasts = [1,0.5];
% (stim parameters)
sigma = [15,15];
spatialFrequency = 0.01;
startingAzimuth = 90;
responseDisplacement = 90;

% Timing
prestimQuiescentTime = 0.5;
cueInteractiveDelay = 0;
iti = 5;

% Wheel parameters
quiescThreshold = 1;
wheelGain = 2;

%% Set up the wheel

wheel = inputs.wheel.skipRepeats();

%% when to present stimuli & allow visual stim to move

stimulusOn = events.newTrial.delay(p.preStimulusQuiescence); % delay the stimulus onset by (preStimulusQuiescence) ms after the trial starts
interactiveOn = stimulusOn.delay(p.postStimulusQuiescence); % delay the interactive period by (postStimulusQuiescence) ms after the stimulus appears

%% wheel position to stimulus displacement
wheelOrigin = wheel.at(interactiveOn); % only start sampling the wheel position sampled once you get to the (interactiveOn) part of the trial
targetDisplacement = p.wheelGain*(wheel - wheelOrigin); % determine the displacement (multiplied by an arbitrary gain coefficient)

%% response at threshold detection
% threshold is when the absolute amount of target displacement is equal or
% greater than the starting azimuth
threshold = interactiveOn.setTrigger(abs(targetDisplacement) >= abs(p.targetAzimuth));
% determine where the target ended up (negative because displacement 
% is opposite sign to initial position) (left = -, right = +)
response = -sign(targetDisplacement.at(threshold));

%%%% feedback
%If the signs of the target azimuth and wheel response are the same, it's a
%correct response (+feedback); if they differ, it's an incorrect
%response (-feedback)
feedback =  sign(p.targetAzimuth.at(response))*response;

%% feedback
audio.noiseBurst = p.noiseBurstAmp.mapn(...
  p.nAudChannels,...
  p.audSampleRate,...
  @(a,n,r)a*randn(n,r)).at(feedback < 0);
outputs.reward = p.rewardSize.at(feedback > 0); % reward only on positive feedback
stimulusOff = response.map(true).delay(p.feedbackDuration);

%% target azimuth
azimuth = cond(...
    stimulusOn.to(interactiveOn), 0,...
    interactiveOn.to(threshold), targetDisplacement,...
    threshold.to(stimulusOff),  -response*abs(p.targetAzimuth));

%% performance and contrast

% Test stim left
target = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
target.orientation = p.targetOrientation;
target.altitude = 0;
target.sigma = [9,9];
target.spatialFrequency = p.spatialFrequency;
target.phase = 2*pi*events.newTrial.map(@(v)rand);   %random phase
target.contrast = contrastLeft;
target.azimuth = -p.targetAzimuth + azimuth;
target.show = stimulusOn.to(stimulusOff);

visStim = target;

%% event handler

% nextCondition = feedback > 0;
nextCondition = feedback > 0 | p.repeatIncorrect == false;

% we want to save these signals so we put them in events with appropriate names
events.stimulusOn = stimulusOn;
% evts.stimulusOff = stimulusOff;
events.contrast = p.targetContrast.map(@diff);
events.azimuth = azimuth;
events.response = response;
events.feedback = feedback;
events.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));
events.endTrial = nextCondition.at(stimulusOff).delay(p.interTrialDelay);

