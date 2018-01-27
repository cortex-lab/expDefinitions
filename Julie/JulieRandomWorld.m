function JulieRandomWorld(t, events, parameters, visStim, in, out, audio)

load('\\zserver\data\expInfo\JL005\2017-06-28\2\2017-06-28_2_JL005_parameters.mat')
pars = parameters;
 
global pars
%rand .. block.events.azimuthValues() 
%rand.. select block.events.contrastValues

%if want to replicate, get trial num from block.trialNumValues? 

% display contrast or play beep exclusively and randomly on every trial

% Set up stim

%% Visual stimulus
sigma = [9,9];
altitude = 0;
phase = 2*pi*events.newTrial.map(@(v)rand);

%parameters
spatialFrequency = pars.spatialFrequency;
orientation = pars.targetOrientation;


%% Auditory stimulus
audioSampleRate = 44100;
onsetToneFreq = pars.onsetToneFrequency;
% onsetToneDuration = 0.1;
% onsetToneRampDuration = 0.01;
nAudChannels = 2;
rewardToneFreq = pars.rewardToneFrequency;
noiseBurstDur = 1; 

%% Initialize trial data
trialDataInit = events.expStart.mapn(@init_trial).subscriptable;

%% Set up the current trial
trialData = events.newTrial.scan(@update_trial,trialDataInit).subscriptable;

%% Run the current trial
stimOn = events.newTrial.delay(0.2);
stimOff = stimOn.delay(1);

%visual stimulus
stim = vis.grating(t, 'sinusoid', 'gaussian');
stim.orientation = orientation; 
stim.altitude = altitude;
stim.sigma = sigma;
stim.spatialFrequency = spatialFrequency;
stim.phase = phase;

stim.azimuth = trialData.azimuth;
stim.contrast = trialData.contrast.at(stimOn);
%stim.side or something?? 

stim.show = stimOn.to(stimOff);
visStim.stim = stim;

%auditory stimulus 
toneSamples = trialData.onsetTone*events.newTrial.map(@(x) ...
    aud.pureTone(onsetToneFreq,0.1,audioSampleRate, ...
    0.02,nAudChannels));
audio.onsetTone = toneSamples.at(stimOn);


noiseBurstSamples = trialData.noiseBurst*events.newTrial.map(@(x) ...
    randn(nAudChannels, noiseBurstDur*audioSampleRate));
audio.noiseBurst = noiseBurstSamples.at(stimOn);

rewardToneSamples = trialData.rewardTone*events.newTrial.map(@(x) ...
    aud.pureTone(rewardToneFreq,0.1,audioSampleRate, ...
    0.02,nAudChannels));

audio.rewardTone = rewardToneSamples.at(stimOn);

rewardSize = trialData.valveClick*2; 
reward = rewardSize.at(stimOn); 
out.reward = reward;

events.endTrial = stimOff.delay(pars.interTrialDelay);
events.valveClick = trialData.valveClick; 
events.contrast = trialData.contrast;
events.azimuth = trialData.azimuth;
events.onsetTone = trialData.onsetTone;
events.rewardTone = trialData.rewardTone;
events.noiseBurst = trialData.noiseBurst;

events.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));


end


function trialDataInit = init_trial(newTrial) %input is scanned events.newTrial 

%first trial starts with contrast thing 
trialDataInit = struct;
trialDataInit.azimuth = 30;
trialDataInit.side = 1; 
trialDataInit.contrast = 0.5;

end


function trialData = update_trial(trialData,newTrial)
global pars
nTrialTypes = 5; %ew 
trialType = zeros(nTrialTypes,1); 
trialType(randi(nTrialTypes)) = 1; %choose only one "type" to display  

trialData.visStim = trialType(1); %stimulus should have variable azimuth 

if trialType(1)
    azimuths = -pars.targetAzimuth:pars.targetAzimuth; %ugh
    trialData.azimuth = azimuths(randi(length(azimuths)));
    trialData.side = sign(trialData.azimuth);
    try
        contrasts = [0, 0.06, 0.12, 0.25, 0.5];
        trialData.contrast = contrasts(randi(length(contrasts))); 
    catch
        trialData.contrast = 0.5; %idk??
        trialData.side = 1; 
        trialData.azimuth = 30; 
    end
else
    trialData.contrast = 0; 
    trialData.azimuth = 0;
    trialData.side = 0; 
end 
trialData.valveClick = trialType(2);
if trialData.valveClick
    probValveAndReward = rand(1);
    if probValveAndReward<0.3
        trialData.rewardTone = 1; %30% probability concurrent 
    end
end 
trialData.onsetTone = trialType(3);
trialData.rewardTone = trialType(4);
trialData.noiseBurst = trialType(5);


end