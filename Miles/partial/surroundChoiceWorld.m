function surroundChoiceWorld(t, evts, pars, vs, inp, out, audio)
%simpleChoiceWorld Summary of this function goes here
%   Detailed explanation goes here

% make some short names
p = pars;
wheel = inp.wheel.skipRepeats();
audioSR = 192e3;

%% when to present stimuli & allow visual stim to move
onsetToneSamples = p.onsetToneAmplitude*...
  mapn(p.onsetToneFreq, p.onsetToneDuration, audioSR, p.onsetToneRampDuration, @aud.pureTone);
onsetToneOn = evts.newTrial.delay(p.onsetToneDelay);
audio.onsetTone = onsetToneSamples.at(onsetToneOn);
stimulusOn = evts.newTrial.delay(p.stimulusDelay);
interactiveOn = stimulusOn.delay(p.interactiveDelay);

%% wheel position to stimulus displacement
wheelOrigin = wheel.at(interactiveOn);
targetDisplacement = p.wheelGain*(wheel - wheelOrigin); 

%% response at threshold detection
threshold = interactiveOn.setTrigger(...
  abs(targetDisplacement) >= abs(p.targetAzimuth));
% negative because displacement is opposite sign to initial position
response = -sign(targetDisplacement.at(threshold));

%% feedback
feedback =  sign(p.targetAzimuth.at(response))*response;
audio.noiseBurst = p.noiseBurstAmp.map(@(a)a*randn(2, audioSR)).at(...
  feedback < 0);
reward = p.rewardSize.at(feedback > 0); 
out.reward = reward;

stimulusOff = response.map(true).delay(1);
stimulusPresent = stimulusOn.to(stimulusOff);

%% target stimulus
targetLeft = vis.grating(t, 'sinusoid', 'gaussian');
surroundLeft = vis.grating(t, 'sinusoid', 'gaussian');
patch = vis.grating(t, 'circle', 'none');
targetRight = vis.grating(t, 'sinusoid', 'gaussian');
surroundRight = vis.grating(t, 'sinusoid', 'gaussian');

surroundRight.orientation = 90;
surroundLeft.orientation = 90;

% target = vis.grating(t, 'sinusoid', 'gaussian') * p.Contrast;   %EJ test 28/08/15
targetLeft.phase = 2*pi*evts.newTrial.map(@(v)rand); % random phase on each trial
targetRight.phase = 2*pi*evts.newTrial.map(@(v)rand); % random phase on each trial
surroundLeft.phase = 2*pi*evts.newTrial.map(@(v)rand); % random phase on each trial
surroundRight.phase = 2*pi*evts.newTrial.map(@(v)rand); % random phase on each trial

targetLeft.altitude = p.targetAltitude;
targetRight.altitude = p.targetAltitude;
surroundLeft.altitude = p.targetAltitude;
surroundRight.altitude = p.targetAltitude+15;
patch.altitude = p.targetAltitude;

targetLeft.sigma = p.targetSigma;
targetRight.sigma = p.targetSigma;
surroundLeft.sigma = p.targetSigma*2;
surroundRight.sigma = p.targetSigma*2;
% patch.sigma = p.targetSigma*1.3;

targetLeft.spatialFrequency = p.targetSpatialFrequency;
targetRight.spatialFrequency = p.targetSpatialFrequency;
surroundLeft.spatialFrequency = p.targetSpatialFrequency;
surroundRight.spatialFrequency = p.targetSpatialFrequency;
% patch.spatialFrequency = 10000000;

targetAzimuth = p.targetAzimuth + cond(...
  stimulusOn.to(interactiveOn), 0,... % no offset during fixed period
  interactiveOn.to(response),   targetDisplacement,...%offset by wheel
  response.to(stimulusOff),    -response*abs(p.targetAzimuth));%final response;
targetRight.azimuth = targetAzimuth;
surroundRight.azimuth = targetAzimuth;
targetLeft.azimuth = targetAzimuth - 2*p.targetAzimuth;
surroundLeft.azimuth = targetAzimuth - 2*p.targetAzimuth;
patch.azimuth = targetAzimuth - 2*p.targetAzimuth;

targetLeft.show = stimulusPresent;
targetRight.show = stimulusPresent;
surroundLeft.show = stimulusPresent;
surroundRight.show = stimulusPresent;
patch.show = stimulusPresent;

vs.targetLeft = targetLeft; % put target in visual stimuli set
vs.targetRight = targetRight; % put target in visual stimuli set
vs.surroundLeft = surroundLeft; % put target in visual stimuli set
vs.surroundRight = surroundRight; % put target in visual stimuli set
vs.patch = patch; % put target in visual stimuli set

targetLeft.contrast = p.contrast;
targetRight.contrast = p.contrast;
surroundLeft.contrast = p.contrast;
surroundRight.contrast = p.contrast;
% patch.contrast = 1000000;

%% misc
nextCondition = feedback > 0; % advance trial condition if correct

% we want to save these so we put them in events with appropriate names
evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.interactiveOn = interactiveOn;
evts.targetAzimuth = targetAzimuth;
evts.response = response;
evts.feedback = feedback;
evts.totalReward = reward.scan(@plus, 0).map(@(r)sprintf('%.1fµl', r));
% 'endTrial' is a special event we create that will be used by the
% experiment to advance the trial
evts.endTrial = nextCondition.at(stimulusOff);

end