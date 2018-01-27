function AP_visAudioPassive(t, events, parameters, visStim, inputs, outputs, audio)
% AP 2017-09-22: present random tones and visual stimuli

%% Set up stimuli

% Make these static for now (dumb signals problems makes this difficult)
staticParameters.numRepeats = 100;
staticParameters.stimTime = 0.5;
staticParameters.minITI = 1;
staticParameters.maxITI = 2;
staticParameters.stepITI = 0.1;
staticParameters.volume = 0.3;
staticParameters.bufferTime = 10;


% Visual stim
spatialFreq = 1/15;
contrast = 1;
stimFlickerFrequency = 5;
orientation = 45; 


%% Stim times

% Visual

visual_itiTimes = randsample(staticParameters.minITI:staticParameters.stepITI:staticParameters.maxITI,10,true);
visual_startTimes = staticParameters.bufferTime + cumsum(visual_itiTimes + staticParameters.stimTime);


%% Present stim

% Visual
visualOnset = t.map(@(t) sum(t > visual_startTimes)).skipRepeats;

stimFlicker = mod(skipRepeats(floor((t - t.at(visualOnset))/(1/stimFlickerFrequency))),2);
stim = vis.grating(t, 'square', 'gaussian');
stim.spatialFreq = spatialFreq;
stim.contrast = contrast;

stim.orientation = orientation;
stim.phase = pi*stimFlicker;

stim.azimuth = 0;
stim.elevation = 0;
stim.sigma = [10,10];stim.show = visualOnset.to(visualOnset.delay(staticParameters.stimTime));
visStim.stim = stim;

endTrial = t.at(visual_startTimes(end)).skipRepeats;

%% Events

events.visualOnset = visualOnset;
% events.visualParams = events.expStart.map(@(x) visual_stim_shuffle);

events.endTrial = endTrial;

end

















