function testWorld(t, evts, p, vs, in, out, audio)
%% parameters
%% when to present stimuli & allow visual stim to move
% stimulusOn = evts.newTrial.delay(p.stimulusDelay);
adapterOn = evts.newTrial;
adapterOff = adapterOn.delay(5);
stimulusOn = adapterOff.delay(1);
interactiveOn = stimulusOn.delay(1);

azimuth = p.targetAzimuth-cond(...
    stimulusOn.to(interactiveOn),0,...
    true,t-t.at(interactiveOn));
stimulusOff = azimuth==0;

%% performance and contrast
% Adapter
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
target.phase = 0;
target.contrast = 1;
target.azimuth = azimuth;
target.show = stimulusOn.to(stimulusOff);

vs.target = target; % store target in visual stimuli set


%% misc
% we want to save these signals so we put them in events with appropriate names
evts.stimulusOn = adapterOn;
evts.adapterOff = adapterOff;
evts.firstTrial = evts.trialNum<2;
evts.stimulusOff = stimulusOff;
evts.azimuth = azimuth;
evts.endTrial = stimulusOff.delay(1);
end