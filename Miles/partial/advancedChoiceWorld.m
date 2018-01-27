function advancedChoiceWorld(t, evts, p, vs, in, out, audio)
%% advancedChoiceWorld
% Burgess 2AFUC task with contrast desctimination
% 2017-03-25 Added Contrast discrimination MW

%% parameters
wheel = in.wheel.skipRepeats();
nAudChannels = 2;
audSampleRate = 196e3;
contrastLeft = p.targetContrast(1);
contrastRight = p.targetContrast(2);

%% when to present stimuli & allow visual stim to move
stimulusOn = evts.newTrial;
interactiveOn = stimulusOn.delay(p.interactiveDelay);

onsetToneSamples = p.onsetToneAmplitude*...
    aud.pureTone(10500, 0.1, audSampleRate, 0.02, 2);
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
audio.noiseBurst = p.noiseBurstAmp.map(...
  @(a)a*randn(nAudChannels,audSampleRate)).at(feedback == 0);
reward = p.rewardSize.at(feedback > 0); 
out.reward = reward;

%% target azimuth
azimuth = cond(...
    stimulusOn.to(interactiveOn), 0,...
    interactiveOn.to(threshold), targetDisplacement,...
    threshold.to(stimulusOff),  -response*abs(p.targetAzimuth));

%% performance and contrast
% Adapter
phaseChange = skipRepeats(floor(t*p.phaseFreq)/p.phaseFreq);

% Test stim left
targetLeft = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetLeft.orientation = p.targetOrientation;
targetLeft.altitude = 0;
targetLeft.sigma = [9,9];
targetLeft.spatialFrequency = p.spatialFrequency;
targetLeft.phase = 2*pi*phaseChange.map(@(v)rand);
targetLeft.contrast = contrastLeft;
targetLeft.azimuth = -p.targetAzimuth + azimuth;
targetLeft.show = stimulusOn.to(stimulusOff);

vs.targetLeft = targetLeft; % store target in visual stimuli set

% Test stim right
targetRight = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetRight.orientation = p.targetOrientation;
targetRight.altitude = 0;
targetRight.sigma = [9,9];
targetRight.spatialFrequency = p.spatialFrequency;
targetRight.phase = 2*pi*phaseChange.map(@(v)rand);
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
end