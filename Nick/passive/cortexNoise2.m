function cortexNoise2(t, evts, p, vs, inputs, outputs, audio, varargin)
% Experiment definition file for the "sparse noise on cortex" experiments. 
%
% Goal:
% - control galvos to aim a laser at various different sites on the brain
% - control the laser output intensity to have different amplitudes and
% durations
% - optionally show visual stimuli (full field checkerboard with reversals)

fprintf(1, 'version 0.94!\n');

if ~isempty(varargin)
    fprintf(1, 'received rig\n');
    rig = varargin{1};
else
    fprintf(1, 'no rig received\n');
    rig = [];
end

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

samplerFs = 15;

nAz = 10;
nAl = 36;

sampler = skipRepeats(floor(t*samplerFs)); % to run a command at a certain sampling rate

stimuliTracker = sampler.scan(...
  @checkerFlip, ...
  makeChecker(nAz, nAl));

myChecker = vis.checker6(t);
myChecker.pattern = skipRepeats(stimuliTracker*p.visualContrast);
% myChecker.azimuths = lowerLeft(1) + gridSpacing(1)*(0:nAz-1);
% myChecker.altitudes = lowerLeft(2) + gridSpacing(2)*(0:nAl-1);
% myChecker.rectSizeFrac = [1 1];
% myChecker.azimuthRange =  [-132 132];
% myChecker.altitudeRange = [-36 36];
% myChecker.colour = squareColor;
vs.myChecker = myChecker;


%% puffs
% clickOnset = evts.newTrial.delay(p.puffDelay); % airpuff happens after specified delay
% outputs.reward = clickOnset*rewardSize;

%% laser/galvo: new method

% map(evts.expStart, @(x)daqInitialize(rig));
% dummy = evts.expStart.onValue(@(x)myDaqInit(x, rig));
dummy = mapn(p.nPulsesPerTrial.at(evts.expStart), ...
    p.laserAmp.at(evts.expStart), ...
    p.positionX.at(evts.expStart), ...
   p.positionY.at(evts.expStart), ...
   p.laserDuration.at(evts.expStart), ...
   p.laserOnsetDelay.at(evts.expStart), ...
   p.mWperV.at(evts.expStart), ...
   p.laserPulseType.at(evts.expStart), ...
   @(a, b, c, d, e, f, g, h)myDaqInit(a, b, c, d, e, f, g, h, rig));

% galvoPars = mapn(p.nPulsesPerTrial, @(x){x});
trialDuration = mapn(p.nPulsesPerTrial.at(evts.newTrial), ...
    p.laserAmp.at(evts.newTrial), ...
    p.positionX.at(evts.newTrial), ...
   p.positionY.at(evts.newTrial), ...
   p.laserDuration.at(evts.newTrial), ...
   p.laserOnsetDelay.at(evts.newTrial), ...
   p.mWperV.at(evts.newTrial), ...
   p.laserPulseType.at(evts.newTrial), ...
   @(a, b, c, d, e, f, g, h)galvoGen(a, b, c, d, e, f, g, h, rig));

% map(evts.newTrial.delay(0.1), @(x)daqTrigger(rig));
% dummy2 = evts.newTrial.delay(0.1).onValue(@(x)myDaqTrig(x, rig));
% dummy2 = mapn(p.nPulsesPerTrial.at(evts.newTrial), @(a)daqTrigger(a, rig));
dummy2 = mapn(p.nPulsesPerTrial.at(evts.newTrial), ...
    p.laserAmp.at(evts.newTrial), ...
    p.positionX.at(evts.newTrial), ...
   p.positionY.at(evts.newTrial), ...
   p.laserDuration.at(evts.newTrial), ...
   p.laserOnsetDelay.at(evts.newTrial), ...
   p.mWperV.at(evts.newTrial), ...
   p.laserPulseType.at(evts.newTrial), ...
   @(a, b, c, d, e, f, g, h)myDaqTrig(a, b, c, d, e, f, g, h, rig));
%% misc
% trialEnd = evts.newTrial.delay(p.trialLenMin+rand(1)*(p.trialLenMax-p.trialLenMin));
% evts.endTrial = trialEnd; 
evts.endTrial = evts.newTrial.delay(trialDuration+p.interTrialInterval.at(trialDuration));

% we want to save the timing of these so we put them in evts with appropriate names
% evts.beepOnset = beepOnset;
% evts.clickOnset = clickOnset;
% evts.laserPars = laserPars;
evts.dummy = dummy;
evts.dummy2 = dummy2;

%% default parameter values
try
    % p.beepFrequency = 8000;
    %     p.puffDelay = 0.5;

%     p.trialLenMin = 0.1;
%     p.trialLenMax = 0.2;

    p.laserDuration = [0.002 0.005 0.01]'; % s
    p.laserRampF = 40;
    p.laserAmp = [0 1 2 4 8 16 32 64]';
    p.laserOnsetDelay = [0.03 0.04 0.5]'; % a range, or an exponential (min, mean, max)
    p.laserPulseType = 1; %1=square, 2=raised cosine
    p.nPulsesPerTrial = 5;
    
    allPos = expandedBrainCoords(); % from github/cortex-lab/kilotrodeRig/
    allPos(allPos==0) = 1e-6; % for this hacky persistence thing, see hw.DaqSingleScan
    p.positionX = allPos(1,:)';
    p.positionY = allPos(2,:)';
    
    p.visualContrast = 1;
    
    p.mWperV = 15.23; % scaling factor for laser power  = 74.3/4.88
    
    p.interTrialInterval = 1;
        
catch ex
    disp(ex)
end


function dummy = myDaqInit(a, b, c, d, e, f, g, h, rig)

s = rig.daqController.DaqSession;
if isempty(s.Connections)
    fprintf(1, 'initializing daq\n');
    s.addTriggerConnection('external', 'Dev1/PFI1', 'StartTrigger');
    s.addTriggerConnection('external', 'Dev2/PFI2', 'StartTrigger');    
    s.ExternalTriggerTimeout = Inf;
end
tr = rig.daqController.DigitalDaqSession;
tr.outputSingleScan(0);
dummy = true;

function dummy = myDaqTrig(a, b, c, d, e, f, g, h, rig)
fprintf(1, 'sending trigger\n');
tr = rig.daqController.DigitalDaqSession;
tr.outputSingleScan(1);
pause(0.002);
tr.outputSingleScan(0);
dummy = true;

function trialDuration = galvoGen(nPulsesPerTrial, laserAmp, positionX, ...
    positionY, laserDuration, laserOnsetDelay, mWperV, laserPulseType, rig)
% Takes pars, generates waveform to send and sends it
fprintf(1, 'this is galvo gen\n');
nPulse = nPulsesPerTrial;
daqCon = rig.daqController; 
s = daqCon.DaqSession;

laserAmp = laserAmp(randi(numel(laserAmp), nPulse));
randP = randi(numel(positionX), nPulse,1);
xPos = positionX(randP);
yPos = positionY(randP);
pulseDur = laserDuration(randi(numel(laserDuration), nPulse));
if numel(laserOnsetDelay)==2
    pulseInterval = rand(nPulse,1)*diff(laserOnsetDelay)+min(laserOnsetDelay);
elseif numel(laserOnsetDelay)==3
    pulseInterval = exprnd(laserOnsetDelay(2), [nPulse 1])+laserOnsetDelay(1);
    pulseInterval(pulseInterval>laserOnsetDelay(3)) = laserOnsetDelay(3);
else
    pulseInterval = repmat(laserOnsetDelay, nPulse, 1);
end
pars.Fs = s.Rate;
pars.mmPerV = 1/daqCon.SignalGenerators(strcmp(daqCon.ChannelNames, 'galvoX')).Scale;
pars.travelTime = 0.005;
pars.mWperV = mWperV;
wf = galvoWaveform(pars, xPos, yPos, laserAmp, pulseDur, pulseInterval, laserPulseType);

wf = wf+0.12; % hardcoded offset to skip the non-responsive zone of the laser

allWF = zeros(size(wf,2), sum(daqCon.AnalogueChannelsIdx));
allWF(:,strcmp(daqCon.ChannelNames, 'galvoX')) = wf(1,:);
allWF(:,strcmp(daqCon.ChannelNames, 'galvoY')) = wf(2,:);
allWF(:,strcmp(daqCon.ChannelNames, 'laserShutter')) = wf(3,:);

s.queueOutputData(allWF); 
s.startBackground;

trialDuration = size(allWF,1)/s.Rate; 

function checker = makeChecker(nAz, nAl)
[xx,yy] = meshgrid(1:nAz, 1:nAl);
checker = ( mod(xx,2)==0 & mod(yy,2)==0 ) | ( mod(xx,2)==1 & mod(yy,2)==1 );
checker = (double(checker)'-0.5)*2;

function checkerOut = checkerFlip(checkerIn,~)
checkerOut = -1*checkerIn;


