function advancedChoiceWorldZMAZE_Bigger(t, evts, p, vs, in, out, audio)
%% advancedChoiceWorld
% Burgess 2AUFC task with contrast discrimination
% 2017-03-25 Added contrast discrimination MW
% 2017-05-03 Added modifications for blue rigs MW/JL
% 2017-05-05 Added reward tone JL 

%% parameters
wheel = in.wheel.skipRepeats();

numAudChannels = 2; %PC - need "numAudChannels" for signals to recognise? 
onsetToneFreq = p.onsetToneFrequency; %e.g. 3300?
rewardToneFreq = p.rewardToneFrequency; %e.g. 6600?
audSampleRate = 44100; %Check PTB Snd('DefaultRate'); previously: 96kHz
contrastLeft = p.targetContrast(1);
contrastRight = p.targetContrast(2);

%% when to present stimuli & allow visual stim to move
stimulusOn = evts.newTrial;
interactiveOn = stimulusOn.delay(p.interactiveDelay);

onsetToneSamples = p.onsetToneAmplitude*...
    mapn(onsetToneFreq, 0.1, audSampleRate, 0.02, numAudChannels, @aud.pureTone); %aud.pureTone(freq, duration, samprate, "ramp duration", numAudChannels)
audio.onsetTone = onsetToneSamples.at(interactiveOn);

%% wheel position to stimulus displacement
wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
targetDisplacement = p.wheelGain*(wheel - wheelOrigin); 

%% response at threshold detection
responseTimeOver = (t - t.at(interactiveOn)) > p.responseWindow;
threshold = interactiveOn.setTrigger(...
  abs(targetDisplacement) >= abs(p.targetAzimuth) | responseTimeOver);

response = cond(...
    responseTimeOver, 0,...
    true, -sign(targetDisplacement));

response = response.at(threshold);
stimulusOff = threshold.delay(1);

%% feedback
correctResponse = cond(contrastLeft > contrastRight, -1,...
    contrastLeft < contrastRight, 1,...
    contrastLeft == contrastRight, 0);
feedback = correctResponse == response;
feedback = feedback.at(threshold);

noiseBurstSamples = p.noiseBurstAmp*...
    mapn(numAudChannels, p.noiseBurstDur*audSampleRate, @randn);
audio.noiseBurst = noiseBurstSamples.at(feedback==0); 

rewardToneSamples = p.rewardToneAmplitude*...
    mapn(rewardToneFreq, 0.1, audSampleRate, 0.02, numAudChannels, @aud.pureTone);
audio.rewardTone = rewardToneSamples.at(feedback > 0);

reward = p.rewardSize.at(feedback > 0); 
out.reward = reward;

%% target azimuth
azimuth = cond(...
    stimulusOn.to(interactiveOn), 0,...
    interactiveOn.to(threshold), targetDisplacement,...
    threshold.to(stimulusOff),  -response*abs(p.targetAzimuth));

%% performance and contrast

% Test stim left
targetLeft = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetLeft.orientation = p.targetOrientation;
targetLeft.altitude = 0;
targetLeft.sigma = [20, 20];
targetLeft.spatialFrequency = p.spatialFrequency;
targetLeft.phase = 2*pi*evts.newTrial.map(@(v)rand);   %random phase
targetLeft.contrast = contrastLeft;
targetLeft.azimuth = -p.targetAzimuth + azimuth;
targetLeft.show = stimulusOn.to(stimulusOff);

vs.targetLeft = targetLeft; % store target in visual stimuli set

% Test stim right
targetRight = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetRight.orientation = p.targetOrientation;
targetRight.altitude = 0;
targetRight.sigma = [20, 20];
targetRight.spatialFrequency = p.spatialFrequency;
targetRight.phase = 2*pi*evts.newTrial.map(@(v)rand);   %random phase
targetRight.contrast = contrastRight;
targetRight.azimuth = p.targetAzimuth + azimuth;
targetRight.show = stimulusOn.to(stimulusOff);

vs.targetRight = targetRight; % store target in visual stimuli set

%% misc
% nextCondition = feedback > 0;
nextCondition = feedback > 0 | p.repeatIncorrect == false;

% we want to save these signals so we put them in events with appropriate names
evts.stimulusOn = stimulusOn;
% evts.stimulusOff = stimulusOff;
evts.contrast = p.targetContrast.map(@diff);
evts.azimuth = azimuth;
evts.response = response;
evts.feedback = feedback;
evts.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));
evts.endTrial = nextCondition.at(stimulusOff).delay(p.interTrialDelay);

%% Defaults
try
%     p.interTrialDelay=0.5;
%     p.interactiveDelay=0.2;
%     p.noiseBurstAmp = 1;
%     p.onsetToneAmplitude=1;
%     p.responseWindow = 60;
%     p.rewardSize = 2;
%     p.spatialFrequency = 0.1;
%     p.sigma = 9; 
%     p.targetAzimuth = 30;
%     p.targetOrientation = 0;
%     p.wheelGain = 0.3;
%     p.defFunction = '\\zserver.cortexlab.net\Code\Rigging\ExpDefinitions\Julie\advancedChoiceWorldZMAZE_Bigger.m'; 
%     p.rewardToneFrequency = 1650;
%     p.onsetToneFrequency = 825;
%     p.noiseBurstDur = 1;
%     p.rewardToneAmplitude = 1;
%     p.stimulusContrast = [1 0;0 1;0.5 0;0 0.5]'; % conditional parameters have ncols > 1
%     p.repeatIncorrect = false;

catch
end

