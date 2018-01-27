function marioAdaptationWorld(t, evts, p, vs, in, out, audio)
%% abAdaptationWorld
% Passive adaptation stimulus consisting of paired presentations of
% two oriented gratings (either same or orthogonal)
% 
% 2017-12-01 Written by LW


%% early p generation

oris_vec = [90 0; 90 90; 0 90; 0 0];
ISI_vec = [0.25, 0.5, 0.75, 1, 1.5, 2];
phase_vec = [0, pi/4, pi/2, 3*pi/4];
[oris_sel,phase_sel] = generateStimCombinations2(oris_vec,phase_vec);

%% stimulus presentations

stimulusDuration = p.stimulusDuration;

%randomly assign prestimulus and poststimulus periods
minITI = 4;
maxITI = 5;

preStimulusPeriod = map(evts.newTrial, @(x) minITI/2 + (maxITI-minITI)/2*rand(x));

postAPeriod = map(evts.newTrial, @(x) datasample(ISI_vec,1));
%postAPeriod = map(evts.newTrial, @(x) max([min([4 exprnd(3,x,x)]) 2]));
%postAPeriod = p.postAPeriod;
%it is defined in p

postBPeriod = map(evts.newTrial, @(x) minITI/2 + (maxITI-minITI)/2*rand(x));


%tell signals when to turn the stimuli on and off
stimulusAOn = evts.newTrial.delay(preStimulusPeriod);
stimulusAOff = stimulusAOn.delay(stimulusDuration);

stimulusBOn = evts.newTrial.delay(preStimulusPeriod + stimulusDuration + postAPeriod);
stimulusBOff = stimulusBOn.delay(stimulusDuration);

%tell signals when to end the trial
endTrial = evts.newTrial.delay(preStimulusPeriod + stimulusDuration + postAPeriod + stimulusDuration + postBPeriod);

%% stimulus
% Aphase = 2 * pi * map(evts.newTrial, @(x) 1/randi(4));
% Bphase = 2 * pi * map(evts.newTrial, @(x) 1/randi(4));

stimulusA = vis.grating(t, 'square', 'gaussian'); % create a Gabor grating
stimulusA.orientation = p.stimulusOrientations(1);
stimulusA.altitude = p.stimulusAltitude;
stimulusA.sigma = [10,10];
stimulusA.spatialFreq = p.spatialFrequency;
stimulusA.phase = p.stimulusPhases(1);
stimulusA.colour = [0 1 1];
stimulusA.contrast = p.stimulusContrast;
stimulusA.azimuth = p.stimulusAzimuth;
stimulusA.show = stimulusAOn.to(stimulusAOff);

%store stimulus in visual stimuli set
vs.stimulusA = stimulusA; 
stimulusB = vis.grating(t, 'square', 'gaussian'); % create a Gabor grating
stimulusB.orientation = p.stimulusOrientations(2);
stimulusB.altitude = p.stimulusAltitude;
stimulusB.sigma = [10,10];
stimulusB.spatialFreq = p.spatialFrequency;
stimulusB.phase = p.stimulusPhases(2);
stimulusB.colour = [0 1 1]; %CHANGE BACK TO [1 1 1]
stimulusB.contrast = p.stimulusContrast;
stimulusB.azimuth = p.stimulusAzimuth;
stimulusB.show = stimulusBOn.to(stimulusBOff);

%store stimulus in visual stimuli set
vs.stimulusB = stimulusB; 

%% save events struct

evts.stimulusAOn = stimulusAOn;
evts.stimulusAOff = stimulusAOff;
evts.stimulusBOn = stimulusBOn;
evts.stimulusBOff = stimulusBOff;
evts.endTrial = endTrial; 

%% parameter defaults




try
    p.stimulusOrientations = oris_sel';
   % p.postAPeriod = ISI_sel;
    p.stimulusPhases = phase_sel';
    
    p.stimulusDuration = 0.25;
    p.stimulusAzimuth = 0;
    p.stimulusAltitude = 0;
    p.stimulusContrast = 1;
    p.spatialFrequency = 0.1;
catch
end

end