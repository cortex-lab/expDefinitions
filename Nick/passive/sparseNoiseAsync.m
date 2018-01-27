
function sparseNoiseAsync(t, evts, p, vs, inputs, outputs, audio)

% trialLen = 3; % seconds
stimPersistence = 4/60; % seconds
stimulusRate = 2.5; % Hz, on average
gridCenter = [0 0]; % degrees visual angle
gridSize = [20 20]; % degrees visual angle
% gridSpacing = [3.1 15]; % degrees visual angle
gridSpacing = [10 10]; % degrees visual angle
squareSize = [10 10]; % degrees visual angle
squareColor = [0 0 0];
samplerFs = 60;


trialLen = p.trialLen;
% stimPersistence = p.stimPersistence;
% stimulusRate = p.stimulusRate;
% gridCenter = p.gridCenter;
% gridSize = p.gridSize;
% gridSpacing = p.gridSpacing;
% squareSize = p.squareSize;
% squareColor = p.squareColor;
% samplerFs = p.samplerFs;

lowerLeft = gridCenter - gridSize./2;
nAz = floor(gridSize(1)/gridSpacing(1))+1;
nAl = floor(gridSize(2)/gridSpacing(2))+1;

sampler = skipRepeats(floor(t*samplerFs)); % to run a command at a certain sampling rate

stimuliTracker = sampler.scan(...
  @(state, new)sparseNoiseTrack(state, new, stimPersistence, stimulusRate, samplerFs), ...
  zeros(nAz, nAl));
stimuliOn = skipRepeats(stimuliTracker > 0);

myNoise = vis.checker(t);
myNoise.show = stimuliOn;
myNoise.azimuths = lowerLeft(1) + gridSpacing(1)*(0:nAz-1);
myNoise.altitudes = lowerLeft(2) + gridSpacing(2)*(0:nAl-1);
myNoise.rectSize = squareSize;
myNoise.colour = squareColor;
vs.myNoise = myNoise;


%% misc
% trialEnd = evts.newTrial.delay(p.trialLen+p.interTrialInterval);
trialEnd = evts.newTrial.delay(trialLen);
evts.endTrial = trialEnd; % nextCondition.at(trialEnd); CB: nextCondition doesn't exist


% we want to save these so we put them in events with appropriate names
evts.stimuliOn = stimuliOn; % CB: u commented these out
evts.stimuliTracker = stimuliTracker;
evts.sampler = sampler;

end


