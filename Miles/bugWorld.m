function bugWorld(t, evts, p, vs, in, out, audio)
%% when to present stimuli & allow visual stim to move
% stimulusOn = evts.newTrial.delay(p.stimulusDelay);
adapterOn = evts.newTrial;
adapterOff = adapterOn.delay(5);
stimulusOn = adapterOff.delay(1);
interactiveOn = stimulusOn.delay(1);

stimulusOff = interactiveOn.delay(0.5);

%% performance and contrast
% Adapter
phaseChange = skipRepeats(floor(t*8)/8);
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
target.contrast = 1;
target.azimuth = 30;
% target.show = stimulusOn.to(stimulusOff).delay(0.002); % this works with evts.endTrial = stimulusOff.delay(0.5);
% target.show = cond((t-t.at(evts.newTrial))<0.5, false,...
% true,stimulusOn.to(stimulusOff)); % Works with evts.endTrial = stimulusOff.delay(0.5);
target.show = stimulusOn.to(stimulusOff);

vs.target = target; % store target in visual stimuli set

%% misc
feedback = true.at(stimulusOff);
nextCondition = feedback > 0;
% nextCondition = stimulusOff==true;

% we want to save these signals so we put them in events with appropriate names
evts.adapterOn = adapterOn;
evts.adapterOff = adapterOff;
evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.endTrial = nextCondition.at(stimulusOff);% this doesn't work because something about concurrent signals breaks endTrial
%evts.endTrial = stimulusOff.delay(0.5); % this works
%evts.endTrial = nextCondition.at(stimulusOff).map(@logical); % this works
% evts.endTrial = nextCondition.at(stimulusOff).identity; % this works
% evts.endTrial = nextCondition.at(stimulusOff).delay(0.001);

end