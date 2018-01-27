function testWorld(t, evts, p, vs, in, out, audio)
%% parameters

wheel = in.wheel.skipRepeats();

%% when to present stimuli & allow visual stim to move
% stimulusOn = evts.newTrial.delay(p.stimulusDelay);
adapterOn = evts.newTrial;
adapterOff = adapterOn.delay(5);
stimulusOn = adapterOff.delay(1);
interactiveOn = stimulusOn.delay(1);

% azimuth = p.targetAzimuth-cond(...
%     stimulusOn.to(interactiveOn),0,...
%     true,wheel - wheel.at(evts.newTrial));
% azimuth = wheel+90;


%% wheel position to stimulus displacement
wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
targetDisplacement = p.wheelGain*(wheel - wheelOrigin); 

%% response at threshold detection
% responseTimeOver = (t - t.at(interactiveOn)) > p.responseWindow;
threshold = interactiveOn.setTrigger(...
  abs(targetDisplacement) >= abs(p.targetAzimuth));
response = -sign(targetDisplacement);
response = response.at(threshold);
stimulusOff = threshold.delay(0.5);

%% feedback
feedback = 2*(sign(p.targetAzimuth) == response)  - 1;
feedback = feedback.at(threshold);


%% target azimuth
azimuth = p.targetAzimuth + cond(...
    stimulusOn.to(interactiveOn), 0,...
    interactiveOn.to(threshold), targetDisplacement,...
    threshold.to(stimulusOff),  -response*abs(p.targetAzimuth));


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
evts.adapterOn = adapterOn;
evts.adapterOff = adapterOff;
evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.azimuth = azimuth;
evts.feedback = feedback;
evts.endTrial = stimulusOff.delay(1);

end