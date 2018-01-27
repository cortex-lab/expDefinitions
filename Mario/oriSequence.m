function oriSequence(t, events, p, visStim, inputs, outputs, audio)
% MD & LW 2017-12-18: present a shuffled sequence of oriented gratings
% that are uniformly drawn or weighted toward a single 'adaptor'
% orientation

%% Generate the stimulus sequence

stimTime = 0.25;
bufferTime = 10;
nOrientations = 12;
nPhases = 8;
nStim = 2000;
adaptorFrequency = 0; %between 0 and 1
adaptorOrientation = 60;
seedNum = 5; %number of random initializations

[orientationSequence, phaseSequence, stimulusProbabilities] = adaptorSequence(nOrientations, nPhases, nStim, adaptorFrequency, adaptorOrientation, seedNum);

% retrieve the relative probabilities of adaptor and other
unique_probs = unique(stimulusProbabilities);
if length(unique_probs) > 1
    pAdaptor = max(unique_probs);
    pOther = min(unique_probs);
else
    pAdaptor = unique_probs;
    pOther = unique_probs;
end

% log the params
paramValues = [stimTime, bufferTime, nOrientations, nPhases, nStim, adaptorFrequency, adaptorOrientation, pAdaptor, pOther, seedNum];
paramNames = {'stimTime', 'bufferTime', 'numOrientations', 'numPhases', 'numStimuli', 'adaptorFrequency', 'adaptorOrientation', 'adaptorProbability', 'otherProbability', 'seedNum'};

stim_iti_times = ones(1,nStim)*stimTime;
stim_onset_times = bufferTime + cumsum(stim_iti_times) - stimTime;
total_time = stim_onset_times(end) + bufferTime;

%% Present stim

% Visual
stimulusOn = t.map(@(t) sum(t > stim_onset_times)).skipRepeats;
stimulusOff = stimulusOn.delay(stimTime);

% global parameters
stimulus = vis.grating(t, 'square', 'gaussian');
stimulus.spatialFreq = p.spatialFrequency;
stimulus.contrast = p.stimulusContrast;
stimulus.azimuth = p.stimulusLocation(1);
stimulus.elevation = p.stimulusLocation(2);
stimulus.sigma = p.stimulusSigma;

% parameters that vary with each presentation
stimulus.phase = stimulusOn.at(stimulusOn).map(@(x) phaseSequence(x));
stimulus.orientation = stimulusOn.at(stimulusOn).map(@(x) orientationSequence(x));

% onset & offset timing
stimulus.show = stimulusOn.to(stimulusOff);
visStim.stim = stimulus;

% end the trial when the total time is reached
endTrial = events.newTrial.delay(total_time);

%% Events

events.stimulusOnset = stimulusOn;
events.oriSequence = events.expStart.map(@(x) orientationSequence);
events.phaseSequence = events.expStart.map(@(x) phaseSequence);
events.paramValues = events.expStart.map(@(x) paramValues);
events.paramNames = events.expStart.map(@(x) paramNames);

events.endTrial = endTrial;

%% parameter defaults

try
    p.stimulusContrast = 1;
    p.stimulusLocation = [-60; 0];
    p.spatialFrequency = 0.1;
    p.stimulusSigma = 10;
catch
end

end

















