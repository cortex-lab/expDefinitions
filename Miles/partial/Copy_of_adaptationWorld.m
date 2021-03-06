function Copy_of_adaptationWorld(t, evts, p, vs, in, out, audio)
%% adaptationWorld
% Burgess 2AFUC task which displays a full-field adapter stimulus between
% trials.  The phase of all stimuli changes at a specified frequency.
% 2017-03-25 Added Contrast discrimination

%% parameters
wheel = in.wheel.skipRepeats();
nAudChannels = 2;
audSampleRate = 196e3;
contrastLeft = p.targetContrast(1);
contrastRight = p.targetContrast(2);

%% when to present stimuli & allow visual stim to move
adapterOn = evts.newTrial;
adapterOff = adapterOn.delay(...
    cond(evts.trialNum < 2, p.initialAdaptTime, true, p.interTrialAdaptTime));
stimulusOn = adapterOff.delay(0.2);
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
% feedback = 2*(sign(p.targetAzimuth) == response)  - 1;
feedback = correctResponse == response;
feedback = feedback.at(threshold);
audio.noiseBurst = p.noiseBurstAmp.map(...
  @(a)a*randn(nAudChannels,audSampleRate)).at(feedback == 0);
bonus = evts.newTrial.map(@rand);
reward = cond(bonus > 0.8, p.rewardSize*2,...
    true, p.rewardSize); 
out.reward = reward.at(feedback > 0);

%% target azimuth
azimuth = cond(...
    stimulusOn.to(interactiveOn), 0,...
    interactiveOn.to(threshold), targetDisplacement,...
    threshold.to(stimulusOff),  -response*abs(p.targetAzimuth));

%% performance and contrast
% Adapter
phaseChange = skipRepeats(floor(t*p.phaseFreq)/p.phaseFreq);
adapter = vis.grating(t, 'sinusoid', 'none'); % create a full field grating
adapter.orientation = p.adapterOrient;
adapter.spatialFrequency = p.spatialFrequency;
adapter.phase = 2*pi*phaseChange.map(@(v)rand);
adapter.contrast = p.adapterContrast;
adapter.show = adapterOn.to(adapterOff);
vs.adapter = adapter;

% Test stim left
targetLeft = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetLeft.orientation = p.gratingOrient;
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
targetRight.orientation = p.gratingOrient;
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
evts.adapterOn = adapterOn;
% evts.adapterOff = adapterOff;
evts.stimulusOn = stimulusOn;
% evts.stimulusOff = stimulusOff;
evts.contrast = p.targetContrast.map(@diff);
evts.azimuth = azimuth;
evts.response = response;
evts.feedback = feedback;
evts.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1f�l'));
evts.endTrial = nextCondition.at(stimulusOff).delay(p.interTrialDelay);
end