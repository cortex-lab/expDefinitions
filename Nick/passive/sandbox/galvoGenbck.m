function trialDuration = galvoGen(nPulsesPerTrial, laserAmp, positionX, ...
    positionY, laserDuration, laserOnsetDelay, mWperV, laserPulseType, rig)
% Takes pars, generates waveform to send and sends it

nPulse = nPulsesPerTrial;
daqCon = rig.daqController; 
s = daqCon.DaqSession;

laserAmp = laserAmp(randi(numel(laserAmp), nPulse));
xPos = positionX(randi(numel(positionX), nPulse));
yPos = positionY(randi(numel(positionY), nPulse));
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
pars.travelTime = 0.002;
pars.mWperV = mWperV;
wf = galvoWaveform(pars, xPos, yPos, laserAmp, pulseDur, pulseInterval, laserPulseType);

allWF = zeros(size(wf,2), numel(daqCon.ChannelNames));
allWF(:,strcmp(daqCon.ChannelNames, 'galvoX')) = wf(1,:);
allWF(:,strcmp(daqCon.ChannelNames, 'galvoY')) = wf(2,:);
allWF(:,strcmp(daqCon.ChannelNames, 'laserShutter')) = wf(3,:);

s.queueOutputData(allWF); 
s.startBackground;

trialDuration = size(allWF,1)/s.Rate+0.2; %200ms buffer for now