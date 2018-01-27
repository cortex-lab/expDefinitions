function bugWorldClosed(t, evts, p, vs, in, out, audio)
%% bugWorld
% Burgess 2AFUC task which should display a vertical 'adapter' stimulus between
% trials, followed as usual by a moveable 'target' stimulus (horizontal).
% The phase of all stimuli changes at 8Hz.
%
% NB: Without identity added to evts.endTrial line, a plaid is seen on the
% second trial onwards.

%% parameters
wheel = in.wheel.skipRepeats();

%% when to present stimuli & allow visual stim to move
adapterOn = evts.newTrial;
adapterOff = adapterOn.delay(5);
stimulusOn = adapterOff.delay(0.2);
interactiveOn = stimulusOn.delay(0.5);

%% wheel position to stimulus displacement
wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
targetDisplacement = 0.2*(wheel - wheelOrigin); 

%% response at threshold detection
threshold = interactiveOn.setTrigger(...
  abs(targetDisplacement) >= abs(p.targetAzimuth));
response = -sign(targetDisplacement);
response = response.at(threshold);
stimulusOff = threshold.delay(1);

%% feedback
feedback = 2*(sign(p.targetAzimuth) == response) - 1;
feedback = feedback.at(threshold);

%% target azimuth
azimuth = p.targetAzimuth + cond(...
    stimulusOn.to(interactiveOn), 0,...
    interactiveOn.to(threshold), targetDisplacement,...
    threshold.to(stimulusOff),  -response*abs(p.targetAzimuth));

%% performance and contrast
% Adapter
phaseChange = skipRepeats(floor(t*8)/8);
adapter = vis.grating(t, 'sinusoid', 'gaussian'); % create a full field grating
adapter.orientation = 0;
adapter.phase = 2*pi*phaseChange.map(@(v)rand);
adapter.contrast = 1;
adapter.show = adapterOn.to(adapterOff);
vs.adapter = adapter;

% Test stim
target = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
target.orientation = 90;
target.phase = 2*pi*phaseChange.map(@(v)rand);
target.contrast = 1;
target.azimuth = azimuth;
target.show = stimulusOn.to(stimulusOff);

vs.target = target; % store target in visual stimuli set

%% misc
nextCondition = feedback > 0;

% we want to save these signals so we put them in events with appropriate names
evts.adapterOn = adapterOn;
evts.adapterOff = adapterOff;
evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.azimuth = azimuth;
evts.response = response;
evts.feedback = feedback;
% evts.endTrial = nextCondition.at(stimulusOff).identity; % this works
% (also if identity is added to target.show line)
evts.endTrial = nextCondition.at(stimulusOff); % this doesn't work

end