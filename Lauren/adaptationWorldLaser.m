function adaptationWorld2AFC(t, evts, p, vs, in, out, audio)
%% adaptationWorld
% Burgess 2AFUC task which displays a full-field adapter stimulus between
% trials.  The phase of all stimuli changes at a specified frequency.

% 2017-03-25 Added Contrast discrimination
% 2017-07-20 Added aud params for running mice in Blue rigs
% samples.  Also added baited trial capability.
% 2017-10-26 p.wheelGain now in mm/deg units

%% task parameters
wheel = in.wheel.skipRepeats();
nAudChannels = 2;
audSampleRate = p.audSampleRate;
audFreq = p.audFreq;
contrastLeft = p.targetContrast(1);
contrastRight = p.targetContrast(2);

%% laser parameters

% if first trial use initial adapter length, otherwise use the intertrial adat time
adapterDuration = iff(evts.trialNum < 2, p.initialAdaptTime, p.interTrialAdaptTime); 

%% when to present stimuli & allow visual stim to move
adapterOn = evts.newTrial.delay(...
    cond(evts.trialNum < 2, 5, true, 0.5)); % added delay to allow for samples to be loaded in time
adapterOff = adapterOn.delay(adapterDuration);
stimulusOn = adapterOff.delay(0.2);
interactiveOn = stimulusOn.delay(p.interactiveDelay);

onsetToneSamples = p.onsetToneAmplitude*...
    mapn(audFreq, 0.1, audSampleRate, 0.02, nAudChannels, @aud.pureTone);
audio.onsetTone = onsetToneSamples.at(interactiveOn);

%% wheel position to stimulus displacement
wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
millimetersFactor = p.encoderRes.map(@(x)31*2*pi/(x*4)); % convert the wheel gain to a value in mm/deg
targetDisplacement = p.wheelGain*millimetersFactor*(wheel - wheelOrigin); % yoke the stimulus displacment to the wheel movement during closed loop

%% response at threshold detection
responseTimeOver = (t - t.at(interactiveOn)) > p.responseWindow;
threshold = interactiveOn.setTrigger(...
  abs(targetDisplacement) >= abs(p.targetAzimuth) | responseTimeOver);
response = cond(...
    responseTimeOver, 0,...
    true, -sign(targetDisplacement));
response = response.at(threshold);
stimulusOff = threshold.delay(p.feedbackPeriod);

%% feedback
rndDraw = map(evts.newTrial, @(x) sign(rand(x)-0.5));
correctResponse = cond(contrastLeft > contrastRight, -1,... % contrast left
    contrastLeft < contrastRight, 1,... % contrast right
    (contrastLeft == contrastRight) & (rndDraw < 0), -1,... % equal contrast (baited)
    (contrastLeft == contrastRight) & (rndDraw > 0), 1); % equal contrast (baited)

feedback = correctResponse == response;
feedback = feedback.at(threshold);
noiseBurstSamples = p.noiseBurstAmp*...
    mapn(nAudChannels, audSampleRate, @randn);
audio.noiseBurst = noiseBurstSamples.at(feedback==0); 

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
adapter = vis.grating(t, 'sinusoid', 'none'); % create a full field grating
adapter.orientation = p.adapterOrient;
adapter.spatialFreq = p.spatialFrequency;
adapter.phase = 2*pi*phaseChange.map(@(v)rand);
adapter.contrast = p.adapterContrast;
adapter.show = adapterOn.to(adapterOff);
vs.adapter = adapter;

% Test stim left
targetLeft = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetLeft.orientation = p.gratingOrient;
targetLeft.altitude = 0;
targetLeft.sigma = [9,9];
targetLeft.spatialFreq = p.spatialFrequency;
targetLeft.phase = cond(p.targetPhaseChange==1, 2*pi*phaseChange.map(@(v)rand),...
    true, 2*pi*evts.newTrial.map(@(v)rand));
targetLeft.contrast = contrastLeft;
targetLeft.azimuth = -p.targetAzimuth + azimuth;
targetLeft.show = stimulusOn.to(stimulusOff);

vs.targetLeft = targetLeft; % store target in visual stimuli set

% Test stim right
targetRight = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetRight.orientation = p.gratingOrient;
targetRight.altitude = 0;
targetRight.sigma = [9,9];
targetRight.spatialFreq = p.spatialFrequency;
targetRight.phase = cond(p.targetPhaseChange==1, 2*pi*phaseChange.map(@(v)rand),...
    true, 2*pi*evts.newTrial.map(@(v)rand));
targetRight.contrast = contrastRight;
targetRight.azimuth = p.targetAzimuth + azimuth;
targetRight.show = stimulusOn.to(stimulusOff);

vs.targetRight = targetRight; % store target in visual stimuli set

%% Advancing to next trial
% nextCondition = feedback > 0;
% nextCondition = feedback > 0 | p.repeatIncorrect == false;
nextCondition = feedback > 0 | p.repeatIncorrect == false;
evts.endTrial = nextCondition.at(stimulusOff).delay(p.interTrialDelay);

%% Signals to save and display in mc
evts.adapterOn = adapterOn;
% evts.adapterOff = adapterOff;
evts.stimulusOn = stimulusOn;
% evts.stimulusOff = stimulusOff;
evts.contrast = p.targetContrast.map(@diff);
evts.azimuth = azimuth;
evts.response = response;
evts.feedback = feedback;
evts.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));

%% Events used by for managing laser
try
    p.audDevIdx;
    p.audSampleRate = 48000;
    p.audFreq = 8000;
    p.targetContrast = [1 0;0.5 0;0.25 0;0.12 0;0.07 0;0.05 0;0 0;...
        0 0.05;0 0.07;0 0.12;0 0.25;0 0.5;0 1]';
    p.repeatIncorrect = [true true true false false false true...
        false false false true true true];
    p.initialAdaptTime = 60;
    p.interTrialAdaptTime = 5;
    p.interactiveDelay = 0;
    p.wheelGain = 5;
    p.encoderRes = 1024;
    p.responseWindow = Inf;
    p.targetAzimuth = 90;
    p.feedbackPeriod = 0;
    p.noiseBurstAmp = 0.01;
    p.onsetToneAmplitude = 0.5;
    p.rewardSize = 1.7;
    p.phaseFreq = 8;
    p.adapterOrient = 90;
    p.gratingOrient = 90;
    p.spatialFrequency = 0.0667;
    p.adapterContrast = 0.05;
    p.targetPhaseChange = true;
    p.interTrialDelay = 0;
catch
end
end