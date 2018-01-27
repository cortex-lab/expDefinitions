function randWorld(t, evts, p, vs, in, out, audio)
%% parameters
wheel = in.wheel.skipRepeats();

%% when to present stimuli & allow visual stim to move
adapterOn = evts.newTrial;
adapterOff = adapterOn.delay(p.interTrialAdaptTime);
stimulusOn = adapterOff.delay(0.2);
interactiveOn = stimulusOn.delay(p.interactiveDelay);
interactiveDelay = p.interactiveDelay;

stimulusOff = interactiveOn.delay(1);

%% feedback
reward = p.rewardSize.at(stimulusOff); 
out.reward = reward;

%%
phaseChange = skipRepeats(floor(t*5)/5);
adapter = vis.grating(t, 'sinusoid', 'none'); % create a full field grating
adapter.orientation = 90;
adapter.spatialFrequency = 0.1;
adapter.phase = 2*pi*phaseChange.map(@(v)rand);
adapter.contrast = 1;
adapter.show = adapterOn.to(adapterOff);
vs.adapter = adapter;

% Test stim
target = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
target.orientation = 90;
target.altitude = 0;
target.sigma = [9,9];
target.spatialFrequency = 0.1;
target.phase = 2*pi*phaseChange.map(@(v)rand);
target.contrast = 0;
target.azimuth = 0;
target.show = stimulusOn.to(stimulusOff);

vs.target = target; % store target in visual stimuli set

%% misc
% nextCondition = feedback > 0 | evts.repeatNum > 9;

% we want to save these signals so we put them in events with appropriate names
evts.adapterOn = adapterOn;
evts.adapterOff = adapterOff;
evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.interactiveDelay = interactiveDelay;
evts.endTrial = stimulusOff.delay(0.5);

end