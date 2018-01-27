function adaptationWorld(t, evts, p, vs, in, out, audio)
%% adaptationWorld
% Burgess 2AFUC task which displays a full-field adapter stimulus between
% trials.  The phase of all stimuli changes at a specified frequency.
% NB: This version is contrast detection only

%% parameters
wheel = in.wheel.skipRepeats();
nAudChannels = 2;
audSampleRate = 196e3;

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
% response = -sign(targetDisplacement);
response = cond(...
    responseTimeOver, 0,...
    true, -sign(targetDisplacement));
response = response.at(threshold);
stimulusOff = threshold.delay(1);

%% feedback
feedback = 2*(sign(p.targetAzimuth) == response)  - 1;
feedback = feedback.at(threshold);
audio.noiseBurst = p.noiseBurstAmp.map(...
  @(a)a*randn(nAudChannels,audSampleRate)).at(feedback < 0);
reward = p.rewardSize.at(feedback > 0); 
out.reward = reward;

%% target azimuth
azimuth = p.targetAzimuth + cond(...
    stimulusOn.to(interactiveOn), 0,...
    interactiveOn.to(threshold), targetDisplacement,...
    threshold.to(stimulusOff),  -response*abs(p.targetAzimuth));

%% performance and contrast
% Adapter
phaseChange = skipRepeats(floor(t*p.phaseFreq)/p.phaseFreq);
adapter = vis.grating(t, 'sinusoid', 'none'); % create a full field grating
adapter.orientation = p.gratingOrient;
adapter.spatialFrequency = p.spatialFrequency;
adapter.phase = 2*pi*phaseChange.map(@(v)rand);
adapter.contrast = 1;
adapter.show = adapterOn.to(adapterOff);
vs.adapter = adapter;

% Test stim
target = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
target.orientation = p.gratingOrient;
target.altitude = 0;
target.sigma = [9,9];
target.spatialFrequency = p.spatialFrequency;
target.phase = 2*pi*phaseChange.map(@(v)rand);
target.contrast = p.targetContrast;
target.azimuth = azimuth;
target.show = stimulusOn.to(stimulusOff);

vs.target = target; % store target in visual stimuli set

%% misc
nextCondition = feedback > 0;
% nextCondition = feedback > 0 | evts.repeatNum > 9;

% we want to save these signals so we put them in events with appropriate names
evts.adapterOn = adapterOn;
evts.adapterOff = adapterOff;
evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.azimuth = azimuth;
evts.response = response;
evts.feedback = feedback;
% evts.performance = ;
evts.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));
evts.endTrial = nextCondition.at(stimulusOff).delay(p.interTrialDelay);

end