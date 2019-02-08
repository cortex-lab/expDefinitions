function choiceWorld2passive(expRef)
% p = dat.expPath(expRef, 'main', 'master');
% expRef = '2018-09-18_1_LEW009';
data = loadVar(dat.expFilePath(expRef, 'block', 'master'), 'block');
block.inputs.wheelValues = data.inputs.wheelValues;
block.inputs.wheelTimes = data.inputs.wheelTimes;

%%% Delays
% ntrials = length(data.events.endTrialValues);
stimOn = data.events.stimulusOnTimes;
% intOn = data.events.interactiveOnTimes(1:ntrials);
trialOn = data.events.newTrialTimes;
% stimOff = [data.events.newTrialTimes(1) data.events.stimulusOffTimes(1:ntrials)];
iti = ones(1,length(trialOn)).*[data.paramsValues.itiHit]; 
% Add extra second for trials where mouse was incorrect
iti(~data.events.hitValues) = [data.paramsValues(~data.events.hitValues).itiMiss];
preStimulusDelay = stimOn - trialOn;

paramsValues = num2cell([data.events.contrastLeftValues' data.events.contrastRightValues']',1)';
paramsValues(:,2) = num2cell([data.events.wheelGainValues]);
rewards = zeros(1,length(paramsValues)); rewards(data.events.hitValues) = [data.outputs.rewardValues];
paramsValues(:,3) = num2cell(rewards);
paramsValues(:,4) = num2cell(iti);
paramsValues(:,5) = num2cell(preStimulusDelay);

names = {'stimulusContrast', 'wheelGain', 'rewardSize', 'interTrialDelay', 'preStimulusDelay'};

block.paramsValues = cell2struct(paramsValues, names, 2)';

parameters = exp.inferParameters(fullfile(getOr(dat.paths, 'expDefinitions'), 'Miles', 'advancedChoiceWorld.m'));
parameters.stimulusAzimuth = data.paramsValues(1).startingAzimuth;
parameters.stimulusContrast = unique([block.paramsValues.stimulusContrast], 'rows')';
n = size(parameters.stimulusContrast,2);
parameters.numRepeats = repmat(floor(1000/n),1,n); 
parameters.repeatIncorrect = true;
parameters.reponseWindow = data.paramsValues(1).maxRespWindow;
parameters.stimulusOrientation = [0;0];
parameters.spatialFrequency = data.paramsValues(1).spatialFreq;
parameters.sigma = data.paramsValues(1).sigma;
parameters.wheelGain = repmat(data.events.wheelGainValues(1), 1, n);
parameters.interTrialDelay = zeros(1, n);
parameters.preStimulusDelay = zeros(1, n);
parameters.onsetToneAmplitude = data.paramsValues(1).onsetToneAmplitude;
% paramStruct = loadVar(dat.expFilePath(expRef, 'Parameters', 'master'), 'parameters');

% p = exp.Parameters(parameters);
% [globalParams, trialParams] = p.assortForExperiment;
% fieldnames(globalParams)
% assert(all(ismember(fieldnames(block.paramsValues),fieldnames(trialParams))), 'd');
% assert(all(ismember(fieldnames(block.paramsValues),fieldnames(trialParams))), 'd');
subject = dat.parseExpRef(expRef);
dat.newExp(subject, now, parameters);
end