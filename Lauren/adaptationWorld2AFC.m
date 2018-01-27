function adaptationWorld2AFC(t, evts, p, vs, in, out, audio)
%% adaptationWorld
% Burgess 2AFC task which displays a full-field adapter stimulus between
% trials.  The phase of all stimuli changes at a specified frequency.

% 2017-03-25 MW Added Contrast discrimination
% 2017-07-20 MW Added aud params for running mice in Blue rigs
% samples.  Also added baited trial capability.
% 2017-10-26 MW changed p.wheelGain now in mm/deg units
% 2018-01-24 LW stripped out laser params and converted to 2AFC, added comments

%% task parameters

% skipRepeats means that this signal doesn't update if the new value is 
% the same of the previous one (i.e. if the wheel doesn't move)
wheel = in.wheel.skipRepeats();

% audio parameters

nAudChannels = 2;
audSampleRate = p.audSampleRate;
audFreq = p.audFreq;

% where to grab values for the left and right contrasts
contrastLeft = p.targetContrast(1);
contrastRight = p.targetContrast(2);

%% set the adaptation for the trial

% if first trial use initial adapter length, otherwise use the intertrial adat time
adapterDuration = iff(evts.trialNum < 2, p.initialAdaptTime, p.interTrialAdaptTime); 

%% 1. adapter presentation
adapterOn = evts.newTrial.delay(...
    cond(evts.trialNum < 2, 5, true, 0.5)); % added delay to allow for samples to be loaded in time
adapterOff = adapterOn.delay(adapterDuration);

%% stimulus appearance

%stimulus appears after the adapter turns off
stimulusOn = adapterOff.delay(0.1); %was 200 ms...this seems long! LW

%the interactive period can start immediately upon stimulus onset (delay =
%0) or delayed a small bit
interactiveOn = stimulusOn.delay(p.interactiveDelay);

%this is indicated with an onset tone
onsetToneSamples = p.onsetToneAmplitude*...
    mapn(audFreq, 0.1, audSampleRate, 0.02, nAudChannels, @aud.pureTone);

% at the time of 'interactive on', send samples to audio device and log as 'onsetTone'
audio.onsetTone = onsetToneSamples.at(interactiveOn);

%% wheel position to stimulus displacement
% Here we define the multiplication factor for changing the wheel signal
% into mm/deg visual angle units.  The Lego wheel used has a 31mm radius.
% The standard KÜBLER rotary encoder uses X4 encoding; we record all edges
% (up and down) from both channels for maximum resolution. This means that
% e.g. a KÜBLER 2400 with 100 pulses per revolution will actually generate
% *400* position ticks per full revolution.

% wheel position sampled at 'interactiveOn'
wheelOrigin = wheel.at(interactiveOn); 

% convert the wheel gain to a value in mm/deg
millimetersFactor = p.encoderRes.map(@(x)31*2*pi/(x*4)); 

% yoke the stimulus displacment to the wheel movement during closed loop
targetDisplacement = p.wheelGain*millimetersFactor*(wheel - wheelOrigin); 

%% define the response and response threshold 

% response time is over when the time exceeds the response time, p.responseWindow
%(p.responseWindow can be set to Inf)
responseTimeOver = (t - t.at(interactiveOn)) > p.responseWindow;

% the response threshold occurs either:
% 1. when the wheel movement exceeds the preset stimulus azimuth (in either
% direction), or
% 2. when the response time is over (see above)
threshold = interactiveOn.setTrigger(...
  abs(targetDisplacement) >= abs(p.targetAzimuth) | responseTimeOver);

% collect the response. if the response time is over, response = 0,
% otherwise it should be the inverse of the sign of stimulusDisplacement
response = cond(...
    responseTimeOver, 0,...
    true, -sign(targetDisplacement));

% only update the response signal when the threshold has been crossed
response = response.at(threshold);

% keep the stimulus onscreen for an extra amount of time after the response
% is collected
stimulusOff = threshold.delay(p.feedbackPeriod);

%% define correct response and feedback

% on each trial randomly pick -1 or 1 value for use in baited (guess) trials
rndDraw = map(evts.newTrial, @(x) sign(rand(x)-0.5));

% assign the correct response for each trial condition. randomly reward a
% side when the contrast is 0% on both sides
correctResponse = cond(contrastLeft > contrastRight, -1,... % contrast left
    contrastLeft < contrastRight, 1,... % contrast right
    (contrastLeft == contrastRight) & (rndDraw < 0), -1,... % equal contrast (baited)
    (contrastLeft == contrastRight) & (rndDraw > 0), 1); % equal contrast (baited)

% the feedback is a logical indicating whether the mouse's response matches 
% the correct response
feedback = correctResponse == response;

% delay feedback from the threshold ever so slightly (AP recommends)
feedbackDelay = threshold.delay(0.01);

% Only update the feedback signal at the time of the threshold being
% crossed, plus the small delay
feedback = feedback.at(feedbackDelay); 

% When the subject gives an incorrect response, send samples to audio device and log as 'noiseBurst'
noiseBurstSamples = p.noiseBurstAmp*...
    mapn(nAudChannels, audSampleRate, @randn);
audio.noiseBurst = noiseBurstSamples.at(feedback==0); 

% only update when feedback changes to greater than 0
reward = p.rewardSize.at(feedback > 0);

% output this signal to the reward controller
out.reward = reward;

%% stimulus azimuth

%set up how the stimulus should move during parts of the trial
azimuth = cond(...
    stimulusOn.to(interactiveOn), 0,... % before the closed-loop condition, the stimulus is fixed at its starting azimuth
    interactiveOn.to(threshold), targetDisplacement,... % closed-loop condition, where the azimuth is yoked to the wheel
    threshold.to(stimulusOff),  -response*abs(p.targetAzimuth)); % once threshold is reached, the stimulus is fixed again

%% define the visual stimuli

% ADAPTER
phaseChange = skipRepeats(floor(t*p.phaseFreq)/p.phaseFreq);
adapter = vis.grating(t, 'sinusoid', 'none'); % create a full field grating
adapter.orientation = p.adapterOrient;
adapter.spatialFreq = p.spatialFrequency;
adapter.phase = 2*pi*phaseChange.map(@(v)rand);
adapter.contrast = p.adapterContrast;

% when show is true, the stimulus is visible
adapter.show = adapterOn.to(adapterOff);

% store adapter in visual stimuli set
vs.adapter = adapter;

% LEFT STIMULUS
targetLeft = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetLeft.orientation = p.gratingOrient;
targetLeft.altitude = 0;
targetLeft.sigma = [9,9];
targetLeft.spatialFreq = p.spatialFrequency;
targetLeft.phase = cond(p.targetPhaseChange==1, 2*pi*phaseChange.map(@(v)rand),...
    true, 2*pi*evts.newTrial.map(@(v)rand));
targetLeft.contrast = contrastLeft;
targetLeft.azimuth = -p.targetAzimuth + azimuth;

% when show is true, the stimulus is visible
targetLeft.show = stimulusOn.to(stimulusOff);

% store target in visual stimuli set
vs.targetLeft = targetLeft; 

% RIGHT STIMULUS
targetRight = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetRight.orientation = p.gratingOrient;
targetRight.altitude = 0;
targetRight.sigma = [9,9];
targetRight.spatialFreq = p.spatialFrequency;
targetRight.phase = cond(p.targetPhaseChange==1, 2*pi*phaseChange.map(@(v)rand),...
    true, 2*pi*evts.newTrial.map(@(v)rand));
targetRight.contrast = contrastRight;
targetRight.azimuth = p.targetAzimuth + azimuth;

% when show is true, the stimulus is visible
targetRight.show = stimulusOn.to(stimulusOff);

% store target in visual stimuli set
vs.targetRight = targetRight; 

%% advance to next trial

% use the next set of conditional paramters only if positive feedback
% was given, or if the parameter 'Repeat incorrect' was set to false.
nextCondition = feedback > 0 | p.repeatIncorrect == false;

%% log events

% save stimuli events
evts.adapterOn = adapterOn;
evts.adapterOff = adapterOff;
evts.stimulusOn = stimulusOn;
evts.interactiveOn = interactiveOn;
evts.stimulusOff = stimulusOff;
evts.contrast = p.targetContrast.map(@diff);
evts.azimuth = azimuth;

% save the mouse's response and the feedback given
evts.response = response;
evts.feedback = feedback;

% accumulate reward signals and append microliter units
evts.rewardSize = rewardSize;
evts.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));

% end the trial after picking the conditions for the next trial and 
% after a delay period is satisfied
evts.endTrial = nextCondition.at(stimulusOff).delay(p.interTrialDelay);

%% parameter defaults

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
    p.encoderRes = 100;
    p.responseWindow = Inf;
    p.targetAzimuth = 90;
    p.feedbackPeriod = 0.5;
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