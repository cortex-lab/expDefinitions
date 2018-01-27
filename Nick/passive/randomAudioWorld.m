function randomAudioWorld(t, evts, p, vs, inputs, outputs, audio)
%RANDOMWORLD 
%   Just plays various things (stimulus left, right, beep, noise burst,
%   reward) at completely random times, each once per trial

audioSR = 192e3; % fixed for now


% make some short names
wheel = inputs.wheel.skipRepeats();

%% when to present stimuli

negFeedbackDelay = p.trialLen*evts.newTrial.map(@(~)rand);
negFeedback = evts.newTrial.delay(negFeedbackDelay);
audio.noiseBurst = p.noiseBurstAmp.map(@(a)a*randn(2,audioSR)).at(negFeedback);

goCueBeepDelay = p.trialLen*evts.newTrial.map(@(~)rand);
goCueBeep = evts.newTrial.delay(goCueBeepDelay);

toneSamples = p.toneAmplitude*...
  mapn(p.toneFreq, p.toneDuration, audioSR, 0.02, @aud.pureTone);
audio.tone = toneSamples.at(goCueBeep);



%% misc
trialEnd = evts.newTrial.delay(p.trialLen+p.interTrialInterval);
evts.endTrial = trialEnd; % nextCondition.at(trialEnd); CB: nextCondition doesn't exist

% we want to save these so we put them in events with appropriate names

evts.goCueBeep = goCueBeep;
evts.negFeedback = negFeedback;

end