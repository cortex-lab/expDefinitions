function cortexNoise(t, evts, p, vs, inputs, outputs, audio)
% Experiment definition file for the "sparse noise on cortex" experiments. 
%
% Goal:
% - control galvos to aim a laser at various different sites on the brain
% - control the laser output intensity to have different amplitudes and
% durations
% - optionally show visual stimuli (full field checkerboard with reversals)

%% parameters

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


%% visual stimulus: checkerboard

% samplerFs = 6;
% 
% nAz = 10;
% nAl = 36;
% 
% sampler = skipRepeats(floor(t*samplerFs)); % to run a command at a certain sampling rate
% 
% stimuliTracker = sampler.scan(...
%   @checkerFlip, ...
%   makeChecker(nAz, nAl));
% 
% myChecker = vis.checker6(t);
% myChecker.pattern = skipRepeats(stimuliTracker*p.visualContrast);
% % myChecker.azimuths = lowerLeft(1) + gridSpacing(1)*(0:nAz-1);
% % myChecker.altitudes = lowerLeft(2) + gridSpacing(2)*(0:nAl-1);
% % myChecker.rectSizeFrac = [1 1];
% % myChecker.azimuthRange =  [-132 132];
% % myChecker.altitudeRange = [-36 36];
% % myChecker.colour = squareColor;
% vs.myChecker = myChecker;


%% puffs
% clickOnset = evts.newTrial.delay(p.puffDelay); % airpuff happens after specified delay
% outputs.reward = clickOnset*rewardSize;

%% laser/galvo: old method, far too slow

pulseDur = map(p.laserDuration, @chooseOne);
pulseAmp = map(p.laserAmp, @chooseOne)/p.mWperV;
laserPars = mapn(pulseDur, p.laserRampF, pulseAmp, @(x,y,z)[x;y;z]);

outputs.galvoX = p.positionX.at(evts.newTrial);
outputs.galvoY = p.positionY.at(evts.newTrial);
outputs.laserShutter = laserPars.at(evts.newTrial.delay(p.laserOnsetDelay));


%% misc
trialEnd = evts.newTrial.delay(p.trialLenMin+rand(1)*(p.trialLenMax-p.trialLenMin));
evts.endTrial = trialEnd; 

% we want to save the timing of these so we put them in evts with appropriate names
% evts.beepOnset = beepOnset;
% evts.clickOnset = clickOnset;
evts.laserPars = laserPars;

%% default parameter values
try
    % p.beepFrequency = 8000;
    %     p.puffDelay = 0.5;

    p.trialLenMin = 0.1;
    p.trialLenMax = 0.2;

    p.laserDuration = [0.002 0.005 0.01]'; % s
    p.laserRampF = 40;
    p.laserAmp = [0 1 2 4 8 16 32 64]';
    p.laserOnsetDelay = 0.01;

    allPos = expandedBrainCoords(); % from github/cortex-lab/kilotrodeRig/
    allPos(allPos==0) = 1e-6; % for this hacky persistence thing, see hw.DaqSingleScan
    p.positionX = allPos(1,:)';
    p.positionY = allPos(2,:)';
    
    p.visualContrast = 1;
    
    p.mWperV = 74.3/4.88; % scaling factor for laser power    
catch
end


function xScalar = chooseOne(xVector)
% function chooseOne(xVector)
% randomly select one
xScalar = xVector(randi(numel(xVector)));

function checker = makeChecker(nAz, nAl)
[xx,yy] = meshgrid(1:nAz, 1:nAl);
checker = ( mod(xx,2)==0 & mod(yy,2)==0 ) | ( mod(xx,2)==1 & mod(yy,2)==1 );
checker = double(checker)';

function checkerOut = checkerFlip(checkerIn)
checkerOut = -1*checkerIn+1;
