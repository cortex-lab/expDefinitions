function randomWorld(t, evts, p, vs, inputs, outputs, audio)
%RANDOMWORLD 
%   Just plays various things (stimulus left, right, beep, noise burst,
%   reward) at completely random times, each once per trial

audioSR = 192e3; % fixed for now


% make some short names
wheel = inputs.wheel.skipRepeats();

%% when to present stimuli

stimuliOnLeftDelay = p.trialLen*evts.newTrial.map(@(~)rand);
stimuliOnRightDelay = p.trialLen*evts.newTrial.map(@(~)rand);
stimuliOnRight = evts.newTrial.delay(stimuliOnRightDelay);
stimuliOnLeft = evts.newTrial.delay(stimuliOnLeftDelay);
stimOffRight = stimuliOnRight.delay(p.visStimDuration);
stimOffLeft = stimuliOnLeft.delay(p.visStimDuration);
stimulusLeftPresent = stimuliOnLeft.to(stimOffLeft)
stimulusRightPresent = stimuliOnRight.to(stimOffRight)

targetL = vis.grating(t, 'square', 'gaussian');
targetL.phase = 2*pi*evts.newTrial.map(@(~)rand); % random phase on each trial
targetL.altitude = p.targetAltitude;
targetL.sigma = p.targetSigma;
targetL.spatialFreq = p.targetSpatialFrequency;
targetL.azimuth = p.targetAzimuthL;
targetL.orientation = 180*evts.newTrial.map(@(~)rand);
targetL.show = stimulusLeftPresent
vs.targetL = targetL; % put target in visual stimuli set

targetR = vis.grating(t, 'square', 'gaussian');
targetR.phase = 2*pi*evts.newTrial.map(@(~)rand); % random phase on each trial
targetR.altitude = p.targetAltitude;
targetR.sigma = p.targetSigma;
targetR.spatialFreq = p.targetSpatialFrequency;
targetR.azimuth = p.targetAzimuthR;
targetR.orientation = 180*evts.newTrial.map(@(~)rand);
targetR.show = stimulusRightPresent;
vs.targetR = targetR; % put target in visual stimuli set

negFeedbackDelay = p.trialLen*evts.newTrial.map(@(~)rand);
negFeedback = evts.newTrial.delay(negFeedbackDelay);
audio.noiseBurst = p.noiseBurstAmp.map(@(a)a*randn(2,audioSR)).at(negFeedback);

posFeedbackDelay = p.trialLen*evts.newTrial.map(@(~)rand);
posFeedback = evts.newTrial.delay(posFeedbackDelay);
reward = p.rewardSize.at(posFeedback); 
outputs.reward = reward;

goCueBeepDelay = p.trialLen*evts.newTrial.map(@(~)rand);
goCueBeep = evts.newTrial.delay(goCueBeepDelay);

toneSamples = p.toneAmplitude*...
  mapn(p.toneFreq, p.toneDuration, audioSR, 0.02, @aud.pureTone);
audio.tone = toneSamples.at(goCueBeep);



%% misc
trialEnd = evts.newTrial.delay(p.trialLen+p.interTrialInterval);
evts.endTrial = trialEnd; % nextCondition.at(trialEnd); CB: nextCondition doesn't exist

% we want to save these so we put them in events with appropriate names
evts.stimuliOnRight = stimuliOnRight; % CB: u commented these out
evts.stimuliOnLeft = stimuliOnLeft;
evts.goCueBeep = goCueBeep;
evts.negFeedback = negFeedback;
evts.posFeedback = posFeedback;
evts.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));

end