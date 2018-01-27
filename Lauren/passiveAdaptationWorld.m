function passiveAdaptationWorld(t, evts, p, vs, in, out, audio)
%% passiveAdaptationWorld
% Passive adaptation stimulus consisting of a period of flashed random
% orientations (rand period), then a period of a flashed test orientation
% (the test period). Test and rand periods are preceded by exprnd intervals 
% of 2-4 s
% 
% Stimulus duration is constant and offset intervals are randomly jittered
% (stimulus duration + jitter)
% 
% presentationDuration: the duration of a single flashed stimulus
% numPresentations: number of flashed stimuli in each period
% 
% 2017-11-29 Written by LW

%% stimulus presentations

presentationDuration = p.presentationDuration;
numPresentations = p.numPresentations;

%% rand and test stimuli

%keep track of the time during each trial
startTime = skipRepeats(t.at(evts.newTrial));
trialTime = t - startTime;

%randomly assign a prestimulus interval before the rand period and the test
%period
preRandPeriod = map(evts.newTrial, @(x) max([min([4 exprnd(3,x,x)]) 2]));
preTestPeriod = map(evts.newTrial, @(x) max([min([4 exprnd(3,x,x)]) 2]));

%apply random jitter to the stimulus offsets in each period
randJitterIntervals = map(evts.newTrial, @(x) rand(1,numPresentations-1).*.1) + presentationDuration;
testJitterIntervals = map(evts.newTrial, @(x) rand(1,numPresentations-1).*.1) + presentationDuration;
cumRandJitter = map(randJitterIntervals, @(x) cumsum(x + presentationDuration));
cumTestJitter = map(testJitterIntervals, @(x) cumsum(x + presentationDuration));

%assemble the onset times for all stimuli in each period and altogether
randOnTimes = horzcat(preRandPeriod, preRandPeriod + cumRandJitter);
maxRand = map(randOnTimes, @(x) x(end));
testOnTimes = horzcat(preTestPeriod, preTestPeriod + cumTestJitter) + maxRand;
stimulusOnTimes = [randOnTimes, testOnTimes];

%tell signals when to turn the stimuli on and off
stimulusOn = skipRepeats(map2(trialTime, stimulusOnTimes, @onWhen));
stimulusOff = stimulusOn.delay(presentationDuration);
evts.stimOnTimes = stimulusOnTimes;

%tell signals when to end the trial
evts.maxTime = map(stimulusOnTimes, @(x) x(end)+presentationDuration);
endTrial = evts.newTrial.delay(evts.maxTime);

%evts.endRand =(stimulusOff > numPresentations & stimulusOff <= numPresentations*2 & stimulusOff > 0);

%% stimulus

%assign the random and test orientations for the trial
orientationSet = [0; 30; 60; 90; 120; 150];
testOrientation = map(evts.newTrial, @(x) datasample(orientationSet,1)); %assign once per trial
randOrientation = map(stimulusOff, @(x) datasample(orientationSet,1)); %assign once per presentation (this generates more orientations than are shown, so need to carefully extract the right ones in analysis)

%assign the stimulus orientation depending on the point in the trial
orientation = cond(stimulusOff >= numPresentations & stimulusOff < numPresentations*2, testOrientation, true, randOrientation);
stimulus = vis.grating(t, 'square', 'gaussian'); % create a Gabor grating
stimulus.orientation = orientation;
stimulus.altitude = p.stimulusLocation(1);
stimulus.sigma = [10,10];
stimulus.spatialFreq = p.spatialFrequency;
% stimulus.phase = 0;
stimulus.phase = 2 * pi * map(stimulusOff, @(x)rand);
stimulus.contrast = p.stimulusContrast;
stimulus.azimuth = p.stimulusLocation(2);
stimulus.show = stimulusOn.to(stimulusOff);

%store stimulus in visual stimuli set
vs.stimulus = stimulus; 

%% save events struct

evts.startTime = startTime;
% evts.t = t.map(@(t) t); %global time
% evts.trialTime = trialTime;
evts.stimulusOnTimes = stimulusOnTimes;
evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.orientation = orientation;
% evts.testOrientation = testOrientation;
% evts.randOrientation = randOrientation;
evts.stimAzimuth = stimulus.azimuth.subscriptable;
evts.stimAltitude = stimulus.altitude.subscriptable;
evts.endTrial = endTrial; 

%% parameter defaults

%params are hard-coded for now because signals (at least exp.test) doesn't
%like the p. struct. TO FIX

try
    p.presentationDuration = 0.25;
    p.numPresentations = 6;
    p.stimulusContrast = 1;
    p.stimulusLocation = [-60; 0];
    p.spatialFrequency = 0.1;
%     p.gratingOrientations = [0 30 60 90 120 150];
catch
end

end

%% functions

function onWhen = onWhen(trialTime,stimulusOnTimes)
    onWhen = sum(trialTime > stimulusOnTimes);
end