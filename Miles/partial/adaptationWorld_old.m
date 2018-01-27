function adaptationWorld(t, evts, p, vs, in, out, audio)
%% parameters
wheel = in.wheel.skipRepeats();
audioSR = 192e3; % fixed for now
% 2 channels, 196kHz, and []
p.numAudChannels = 2;
p.audSampleRate = 192e3;
p.audDevIdx = [];


%% when to present stimuli & allow visual stim to move
adapterOn = evts.newTrial.delay(p.interTrialDelay);
adapterOff = adapterOn.delay(...
    cond(evts.trialNum < 5, p.initialAdaptTime, true, p.interTrialAdaptTime));
% adapterOff = adapterOn.delay(p.initialAdaptTime);
stimulusOn = adapterOff.delay(0.2);
interactiveOn = sig.quiescenceWatch(p.quiescencePeriod, t, wheel, p.quiescenceThreshold);

% onsetToneSamples = p.onsetToneAmplitude*...
%   mapn(p.stimCueToneFreq, p.stimCueToneDuration, audioSR, p.stimCueToneRampDuration, @aud.pureTone);
onsetToneSamples = p.toneAmplitude*aud.pureTone(10500, 0.1, audioSR, 0.02);
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
    true, sign(targetDisplacement));
response = response.at(threshold);
stimulusOff = threshold.delay(0.5);

%% target azimuth
azimuth = p.targetAzimuth + cond(...
  stimulusOn.to(interactiveOn), 0,...
  interactiveOn.to(threshold), targetDisplacement,...%offset by wheel
  threshold.to(stimulusOff),  response*abs(p.targetAzimuth));

%% feedback
feedback = sign(p.targetAzimuth.at(response))*response; % positive or negative feedback
% 96KHz stereo noist burst waveform played at negative feedback
audio.noiseBurst = p.noiseBurstAmp.map(@(a)a*randn(2, 96e3)).at(feedback <= 0);
reward = p.rewardSize.at(feedback > 0); % reward only on positive feedback
out.reward = reward;

%% Adapter and test stimuli
phaseChange = skipRepeats(floor(t*p.phaseFreq)/p.phaseFreq);

% Adapter
adapter = vis.grating(t, 'sinusoid', 'none'); % create a full field grating
adapter.azimuth = 0;
adapter.orientation = p.gratingOrient;
adapter.spatialFrequency = p.spatialFrequency;
adapter.phase = 2*pi*phaseChange.map(@(v)rand);
adapter.contrast = 1;
adapter.show = adapterOn.to(adapterOff);
vs.adapter = adapter;

% Test stimulus
target = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
target.orientation = p.gratingOrient;
target.altitude = 0;
target.sigma = [9,9];
target.spatialFrequency = 0.1;
target.phase = 2*pi*phaseChange.map(@(v)rand);
target.contrast = p.targetContrast;
target.azimuth = azimuth;
target.show = stimulusOn.to(stimulusOff);

vs.target = target; % store target in visual stimuli set

%% misc
% we want to save these signals so we put them in events with appropriate names
nextCondition = feedback > 0 | evts.repeatNum > 9;

evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.adapterOn = adapterOn;
evts.threshold = threshold;
evts.targetDisplacement = targetDisplacement;
evts.adapterOff = adapterOff;
evts.interactiveOn = interactiveOn;
evts.azimuth = azimuth;
evts.contrast = sign(p.targetAzimuth)*p.targetContrast;
evts.stimOntoOff = stimulusOn.to(stimulusOff);
evts.response = response;
evts.feedback = feedback;
evts.endTrial = nextCondition.at(stimulusOff); % 'endTrial' is a special event used to advance the trial
evts.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));

end