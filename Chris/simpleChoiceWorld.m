function simpleChoiceWorld(t, evts, pars, vs, inp, out, audio)
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
target = vis.grating(t);
target.phase = 2*pi*evts.newTrial.map(@(v)rand); % random phase on each trial
target.altitude = p.targetAltitude;
target.sigma = p.targetSigma;
target.spatialFrequency = p.targetSpatialFrequency;
targetAzimuth = p.targetAzimuth + cond(...
  stimulusOn.to(interactiveOn), 0,... % no offset during fixed period
  interactiveOn.to(response),   targetDisplacement,...%offset by wheel
  response.to(stimulusOff),    -response*abs(p.targetAzimuth));%final response
target.azimuth = targetAzimuth;
target.show = stimulusPresent;
vs.target = target; % put target in visual stimuli set

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

