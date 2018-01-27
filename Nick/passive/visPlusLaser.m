function visPlusLaser(t, evts, p, vs, inputs, outputs, audio)


%% parameters

% flashes
fullFieldSize = [270 90]; % covers the whole screen

% beeps
% beepFreq = p.beepFrequency*evts.newTrial;
% audioSR = 192e3; 

% valve clicks
% rewardSize = 3.5; % controls the duration of the pulse to the valve controller, obscurely


%% beeps
% beepOnset = evts.newTrial; %start the beep at trial onset
% 
% toneSamples = p.beepAmplitude*... % to turn it off, set beepAmplitude=0
%   mapn(beepFreq, p.beepDur*2, audioSR, 0.02, @aud.pureTone);
% audio.tone = toneSamples.at(beepOnset);


%% visual flashes
flashOnset = evts.newTrial.delay(p.visOnsetDelay); %start the flash at trial onset too
flashOffset = flashOnset.delay(p.flashDur); % to turn it off, set flashDur=0

flashOn = flashOnset.to(flashOffset);

% fullField = vis.patch(t, 'rect');
% fullField.dims = fullFieldSize;
% fullField.show = evts.expStart.map(true); 
% vs.fullField = fullField;

contrastLeft = p.stimulusContrast(1);
contrastRight = p.stimulusContrast(2);

leftStimulus = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
leftStimulus.orientation = p.stimulusOrientation;
leftStimulus.altitude = p.stimulusAltitudeLeft;
leftStimulus.sigma = [9,9]; % in visual degrees
leftStimulus.spatialFreq = p.spatialFrequency; % in cylces per degree
leftStimulus.phase = 2*pi*evts.newTrial.map(@(v)rand);   % phase randomly changes each trial
leftStimulus.contrast = contrastLeft;
leftStimulus.azimuth = p.stimulusAzimuthLeft;
leftStimulus.show = flashOn;
vs.leftStimulus = leftStimulus; % store stimulus in visual stimuli set and log as 'leftStimulus'

rightStimulus = vis.grating(t, 'sinusoid', 'gaussian');
rightStimulus.orientation = p.stimulusOrientation;
rightStimulus.altitude = p.stimulusAltitudeRight;
rightStimulus.sigma = [9,9];
rightStimulus.spatialFreq = p.spatialFrequency;
rightStimulus.phase = 2*pi*evts.newTrial.map(@(v)rand);
rightStimulus.contrast = contrastRight;
rightStimulus.azimuth = p.stimulusAzimuthRight;
rightStimulus.show = flashOn; 
vs.rightStimulus = rightStimulus; % store stimulus in visual stimuli set


%% puffs
% clickOnset = evts.newTrial.delay(p.puffDelay); % airpuff happens after specified delay
% outputs.reward = clickOnset*rewardSize;

%% laser

laserPars = mapn(p.laserDuration, p.laserRampF, p.laserAmp, @(x,y,z)[x;y;z]);
outputs.laserShutter = laserPars.at(evts.newTrial.delay(p.laserOnsetDelay));

%% misc
trialEnd = evts.newTrial.delay(p.trialLenMin+rand(1)*(p.trialLenMax-p.trialLenMin));
evts.endTrial = trialEnd; 

% we want to save the timing of these so we put them in evts with appropriate names
% evts.beepOnset = beepOnset;
% evts.clickOnset = clickOnset;
evts.flashOn = flashOn;

%% default parameter values
try
    % p.beepFrequency = 8000;
    p.trialLenMin = 2;
    p.trialLenMax = 3;
    p.flashDur = 1.5;    
%     p.puffDelay = 0.5;
    p.laserDuration = 1;
    p.laserRampF = 40;
    p.laserAmp = 5;
    p.laserOnsetDelay = 0.2;
    p.visOnsetDelay = 0.2;
    p.stimulusAltitudeLeft = 0;
    p.stimulusAltitudeRight = 0;
    p.stimulusOrientation = 45;
    p.spatialFrequency = 0.1;
    p.stimulusAzimuthLeft = -90;
    p.stimulusAzimuthRight = 90;
    p.stimulusContrast = [1; 1];
catch
end

end


