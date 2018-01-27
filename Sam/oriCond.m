function oriCond(t, events, paras, visStim, inputs, outputs, audio)
%% oriCond
% Orientation and reward pairing for classic conditioning
% Created 22-06-2017 SF
% Intertrial delay taken from exp distribution with enforced minimum 07-08-2017 SF

% To do
% Add lick detector input

%% parameters

meanExpInterTrialDelay = paras.meanExpInterTrialDelay;
minInterTrialDelay = paras.minInterTrialDelay;

interTrialDelay = minInterTrialDelay + meanExpInterTrialDelay.map(@exprnd);

% interTrialDelay = 3;

stimulusDuration = paras.stimulusDuration;

rewardDelay = paras.rewardDelay; % Set to 0 to have it given at the end of each stimulus display

% if rewardDelay > stimulusDuration
%     rewardDelay = stimulusDuration;
% end

targetContrast = paras.targetContrast;
% contrast = 1;

ori = paras.targetOrientation;
% ori = 45;

rewardedOri = paras.rewardedOrientation;
% rewardedOri = 45;

alt = paras.targetAltitude;
% alt = 0;

azi = paras.targetAzimuth;
% azi = 0;

sigma = paras.targetSigma;
% sigma = [12, 12];

spatialFreq = paras.spatialFrequency;
% spatialFreq = 0.04;

rewardSizeCorrect = paras.rewardSize;
% rewardSize = 3;

paras.audDevIdx;               %Audio device index to use
numAudChannels = paras.numAudChannels;
audSampleRate = paras.audSampleRate;
onsetToneFreq = paras.onsetToneFreq;
onsetToneDuration = paras.onsetToneDuration;
onsetRampDuration = paras.onsetRampDuration;
onsetToneAmplitude = paras.onsetToneAmplitude;

%% when to present stimuli

stimulusOn = events.newTrial.delay(0.05);
stimulusOff = stimulusOn.delay(stimulusDuration);
stimulusOnOff = stimulusOn.to(stimulusOff);

soundOn = stimulusOn;

audio.soundOn = onsetToneAmplitude*...
    mapn(onsetToneFreq, onsetToneDuration, audSampleRate, onsetRampDuration, numAudChannels, @aud.pureTone); %aud.pureTone(freq, duration, samprate, "ramp duration", nAudChannels)

%% reward at rewarded ori

oriCheck = at(true, stimulusOn.delay(rewardDelay));

rewardSize = cond(ori == rewardedOri, rewardSizeCorrect, true, 0); % Can allow for reward for "unrewarded" stim if wanted, 2017-08-25 SF

rewardTrigger = stimulusOn.setTrigger(oriCheck);

deliverReward = rewardTrigger.to(stimulusOff); 

reward = deliverReward*rewardSize;

outputs.reward = reward;

%% Stimulus

phase = 2*pi*events.newTrial.map(@(v)rand);

target = vis.grating(t, 'sinusoid', 'gaussian');
target.orientation = ori;
target.altitude = alt;
target.azimuth = azi;
target.sigma = sigma; 
target.spatialFreq = spatialFreq;
target.phase = phase;
target.contrast = targetContrast;
target.show = stimulusOnOff;

visStim.target = target;

%% events

% we want to save these signals so we put them in events with appropriate names
events.targetOrientation = ori;
events.rewardedOrientation = rewardedOri;
events.targetPhase = phase;
events.targetContrast = targetContrast;
events.targetAzi = azi;
events.targetAlt = alt;

events.stimulusOnset = t.at(stimulusOn);
events.stimulusOffset = t.at(stimulusOff);

events.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));

events.rewardAmount = cond(deliverReward, deliverReward*rewardSize, true, 0);
events.rewardTime = cond(deliverReward*rewardSize > 0, t.at(deliverReward), true, 0);
events.endTrial = stimulusOff.delay(interTrialDelay);

end




