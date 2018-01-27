function galvo2AUC(t, evts, p, vs, in, out, audio)
%% advancedChoiceWorld
% Burgess 2AFUC task with contrast desctimination
% 2017-03-25 Added Contrast discrimination MW

%% parameters
wheel = in.wheel.skipRepeats();
contrastLeft = p.targetContrast(1);
contrastRight = p.targetContrast(2);
% aDev = p.audDevIdx;               %Audio device index to use

p.laserTypeProportions; %Proportion of (off, on for one location, on for two locations)
p.galvoType;  %(1,2)--(single scan mode, scanning between two sites)
p.laserPower; %Laser power
p.laserOnsetDelays; %Vector of laser onset delays to sample randomly from
p.laserDuration; %how long the laser/galvo should be on for

load 26CoordSet.mat;
% load 4CoordSet.mat;
% load 3CoordSetWithControl.mat;

% load 12CoordSet.mat;
galvoCoords = coordSet*evts.newTrial;

%Random draw of onset delays from a preset collection of values in p.laserOnsetDelays
% laserOnsets = p.laserOnsetDelays*evts.newTrial;
% laserOnsetDelay = at(laserOnsets.map( @(x) randsample(x,1) ) , evts.newTrial);

%Uniform sampling of onset delays. Bounds set in p.laserOnsetDelays
laserOnsetDelay = at( p.laserOnsetDelays.map(@(x) x(1) + (x(2)-x(1))*rand) , evts.newTrial);

laserType = at(p.laserTypeProportions.map(@(x) sum(rand>cumsum(x./sum(x)))), evts.newTrial)*(evts.repeatNum==1);
galvoPos = at(galvoCoords.map(@(x) ceil(rand*size(x,1))*sign(rand-0.5)), evts.newTrial); 

%% when to present stimuli & allow visual stim to move
stimulusOn = evts.newTrial.delay(p.interTrialDelay);

TTL = p.rewardSize.at(evts.newTrial.delay(p.interTrialDelay + laserOnsetDelay) ); %TTL on at new trial + fixed delay + laserOnsetDelay
out.digitalTTL = TTL.to(TTL.delay(0.01));

interactiveOn = stimulusOn.delay(p.interactiveDelay);

onsetToneSamples = p.onsetToneAmplitude*...
    mapn(10500, 0.1, p.audSampleRate, 0.02, p.numAudChannels, @aud.pureTone);
audio.onsetTone = onsetToneSamples.at(interactiveOn);

%% wheel position to stimulus displacement
wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
targetDisplacement = p.wheelGain*(wheel - wheelOrigin); 

%% response at threshold detection
responseTimeOver = (t - t.at(interactiveOn)) > p.responseWindow;
threshold = interactiveOn.setTrigger(...
  abs(targetDisplacement) >= abs(p.targetAzimuth) | responseTimeOver);
response = cond(...
    responseTimeOver, 0,...
    true, -sign(targetDisplacement));
response = response.at(threshold);
stimulusOff = threshold.delay(1.5);

%% feedback
% correctResponse = cond(contrastLeft > contrastRight, -1,...
%     contrastLeft < contrastRight, 1,...
%     contrastLeft == contrastRight, 0);

rndDraw = map(evts.newTrial, @(x) sign(rand(x)-0.5));
correctResponse = cond(contrastLeft > contrastRight, -1,...
    contrastLeft < contrastRight, 1,...
    (contrastLeft + contrastRight == 0), 0,...
    (contrastLeft == contrastRight) & (rndDraw < 0), -1,...
    (contrastLeft == contrastRight) & (rndDraw > 0), 1);

feedback = correctResponse == response;
feedback = feedback.at(threshold);
noiseBurst = mapn(p.noiseBurstAmp,p.numAudChannels,p.audSampleRate,@(a,b,c)a*randn(b,c));
audio.noiseBurst = noiseBurst.at(feedback == 0);
reward = p.rewardSize.at(feedback > 0);
out.reward = reward;

%Set galvo/Laser to terminate 1.5 after stimulus onset

%% target azimuth
azimuth = cond(...
    stimulusOn.to(interactiveOn), 0,...
    interactiveOn.to(threshold), targetDisplacement,...
    threshold.to(stimulusOff),  -response*abs(p.targetAzimuth));

%% performance and contrast
% Test stim left
targetLeft = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetLeft.orientation = p.targetOrientation;
targetLeft.altitude = 0;
targetLeft.sigma = [9,9];
targetLeft.spatialFrequency = p.spatialFrequency;
targetLeft.phase = 2*pi*evts.newTrial.map(@(v)rand);   %random phase
targetLeft.contrast = contrastLeft;
targetLeft.azimuth = -p.targetAzimuth + azimuth;
targetLeft.show = stimulusOn.to(stimulusOff);

vs.targetLeft = targetLeft; % store target in visual stimuli set

% Test stim right
targetRight = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetRight.orientation = p.targetOrientation;
targetRight.altitude = 0;
targetRight.sigma = [9,9];
targetRight.spatialFrequency = p.spatialFrequency;
targetRight.phase = 2*pi*evts.newTrial.map(@(v)rand);   %random phase
targetRight.contrast = contrastRight;
targetRight.azimuth = p.targetAzimuth + azimuth;
targetRight.show = stimulusOn.to(stimulusOff);

vs.targetRight = targetRight; % store target in visual stimuli set

%% misc
% nextCondition = feedback > 0;
nextCondition = feedback > 0 | p.repeatIncorrect == false;

% we want to save these signals so we put them in events with appropriate names
evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.contrastLeft = contrastLeft;
evts.contrastRight = contrastRight;
evts.azimuth = azimuth;
% evts.valveSignal = aDev;
evts.response = response;
evts.feedback = feedback;
evts.laserType = laserType;
evts.laserPower = p.laserPower;
evts.laserOnsetDelay = laserOnsetDelay;
evts.laserDuration = p.laserDuration;
evts.galvoType = p.galvoType;
% evts.galvoAndLaserEnd = galvoAndLaserEnd;
evts.galvoPos = galvoPos;
evts.galvoCoords = galvoCoords;
evts.TTL = TTL;
evts.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));
evts.endTrial = nextCondition.at(stimulusOff.delay(0.5));
% evts.endTrial = nextCondition.at(galvoAndLaserEnd);


end





