function advancedLWChoiceWorld(t, evts, p, vs, in, out, audio)
%% advancedChoiceWorld
% Burgess 2AUFC task with contrast discrimination and baited equal contrast
% trial conditions.  
% 2017-03-25 Added contrast discrimination MW
% 2017-08    Added baited trials (thanks PZH)
% 2017-09-26 Added manual reward key presses
% 2017-10-26 p.wheelGain now in mm/deg units
% 2017-11-23 Added water-reward bias LW

%% some initial parameters

% skipRepeats means that this signal doesn't update if the new value is 
% the same of the previous one (i.e. if the wheel doesn't move)
wheel = in.wheel.skipRepeats();

% get value of rewardKey at experiment start, otherwise it will take the 
% same value each new trial
rewardKey = p.rewardKey.at(evts.expStart); 

% true each time the reward key is pressed
rewardKeyPressed = in.keyboard.strcmp(rewardKey);

% audio parameters
nAudChannels = 2;
audSampleRate = p.audSampleRate; % Check PTB Snd('DefaultRate');

% where to grab values for the left and right contrasts
contrastLeft = p.stimulusContrast(1);
contrastRight = p.stimulusContrast(2);

% get the quiescence threshold from the initial params
quiescThreshold = p.quiescenceThreshold;

%% step 1. prestimulus quiescent period

% for every new trial, choose a prestimulus quiescence period from an 
% exponential distibution(constrained by min = 0.5s & max = 1s)
preStimulusPeriod = map(evts.newTrial, @(x) max([min([1 exprnd(.9,x,x)]) .5]));

% the mouse has to be quiescent during the whole period
% (otherwise the prestimulus period restarts)
prestimQuiescentPeriod = at(preStimulusPeriod,evts.newTrial.delay(0)); 
preStimQuiescence = sig.quiescenceWatch(prestimQuiescentPeriod, t, wheel, quiescThreshold); 

%% step 2. stimulus appearance

% the stimulus appears after the prestimulus period has been fulfilled
stimulusOn = at(true,preStimQuiescence); 

%% step 3. interactive quiescent period

% choose an interactive delay period from an exponential distribution
% (constrained by min = 0.8s and max = 1s)
interactiveDelay = map(evts.newTrial, @(x) max([min([1 exprnd(.9,x,x)]) .8]));

% the mouse has to be quiescent during the whole interactive period
% (otherwise the interactive period restarts)
interactiveQuiescentPeriod = at(interactiveDelay,stimulusOn.delay(0)); 
interactiveQuiescence = sig.quiescenceWatch(interactiveQuiescentPeriod, t, wheel, quiescThreshold); 

%% step 4. go!
% the wheel goes live after the interactive period has been fulfilled,
% and the mouse can move
interactiveOn = at(true,interactiveQuiescence); 

% this is indicated with an onset tone
onsetToneSamples = p.onsetToneAmplitude*...
    mapn(p.onsetToneFrequency, 0.1, audSampleRate, 0.02, nAudChannels, @aud.pureTone); % aud.pureTone(freq, duration, samprate, "ramp duration", nAudChannels)

% at the time of 'interactive on', send samples to audio device and log as 'onsetTone'
audio.onsetTone = onsetToneSamples.at(interactiveOn); 

%% wheel position to stimulus displacement
% Here we define the multiplication factor for changing the wheel signal
% into mm/deg visual angle units.  The Lego wheel used has a 31mm radius.
% The standard KÜBLER rotary encoder uses X4 encoding; we record all edges
% (up and down) from both channels for maximum resolution. This means that
% e.g. a KÜBLER 2400 with 100 pulses per revolution will actually generate
% *400* position ticks per full revolution.

% get the encoder resolution from the preset parameter. this will vary from
% rig to rig
encoderRes = p.encoderResolution;

% wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
% millimetersFactor = map2(p.wheelGain, 31*2*pi/(encoderRes*4), @times); % convert the wheel gain to a value in mm/deg
% stimulusDisplacement = millimetersFactor*(wheel - wheelOrigin); % yoke the stimulus displacment to the wheel movement during closed loop

% wheel position sampled at 'interactiveOn'
wheelOrigin = wheel.at(interactiveOn); 

% convert the wheel gain to a value in mm/deg
millimetersFactor = map(encoderRes, @(x) 31*2*pi/(x*4)); 

% yoke the stimulus displacment to the wheel movement during closed loop
stimulusDisplacement = p.wheelGain*millimetersFactor*(wheel - wheelOrigin); 

%% define the response and response threshold 

% response time is over when the time exceeds the response time, p.responseWindow
%(p.responseWindow can be set to Inf)
responseTimeOver = (t - t.at(interactiveOn)) > p.responseWindow;

% the response threshold occurs either:
% 1. when the wheel movement exceeds the preset stimulus azimuth (in either
% direction), or
% 2. when the response time is over (see above)
threshold = interactiveOn.setTrigger(...
  abs(stimulusDisplacement) >= abs(p.stimulusAzimuth) | responseTimeOver);

% collect the response. if the response time is over, response = 0,
% otherwise it should be the inverse of the sign of stimulusDisplacement
response = cond(...
    responseTimeOver, 0,...
    true, -sign(stimulusDisplacement));

% only update the response signal when the threshold has been crossed
response = response.at(threshold); 

% keep the stimulus onscreen for an extra amount of time after the response
% is collected
stimulusOff = threshold.delay(.5); 

%% define correct response and feedback

% on each trial randomly pick -1 or 1 value for use in baited (guess) trials
rndDraw = map(evts.newTrial, @(x) sign(rand(x)-0.5)); 

% assign the correct response for each trial condition. randomly reward a
% side when the contrast is 0% on both sides
correctResponse = cond(contrastLeft > contrastRight, -1,... % contrast left
    contrastLeft < contrastRight, 1,... % contrast right
    (contrastLeft == contrastRight) & (rndDraw < 0), -1,... % equal contrast (baited)
    (contrastLeft == contrastRight) & (rndDraw > 0), 1); % equal contrast (baited)

% the feedback is a logical indicating whether the mouse's response matches 
% the correct response
feedback = correctResponse == response;

% set a logical for what kind of correct trial it is
correctLeft = feedback & correctResponse == -1;
correctRight = feedback & correctResponse == 1;

% delay feedback from the threshold ever so slightly (AP recommends)
feedbackDelay = threshold.delay(0.01);

% Only update the feedback signal at the time of the threshold being
% crossed, plus the small delay
feedback = feedback.at(feedbackDelay); 

% When the subject gives an incorrect response, send samples to audio device and log as 'noiseBurst'
noiseBurstSamples = p.noiseBurstAmp*...
    mapn(nAudChannels, p.noiseBurstDur*audSampleRate, @randn);
audio.noiseBurst = noiseBurstSamples.at(feedback == 0); 

% Assign reward size based on whether the correct trial was left or right
rewardSize = cond(correctLeft > (correctRight), p.rewardSize(1),... %set the reward for correct left trials
    correctRight > (correctLeft), p.rewardSize(2)); %set the reward for correct right trials

% only update when feedback changes to greater than 0, or reward key is pressed
reward = merge(rewardKeyPressed, feedback > 0);

% output this signal to the reward controller
out.reward = rewardSize.at(reward); 

%% stimulus azimuth

%set up how the stimulus should move during parts of the trial
azimuth = cond(...
    stimulusOn.to(interactiveOn), 0,... % before the closed-loop condition, the stimulus is fixed at its starting azimuth
    interactiveOn.to(threshold), stimulusDisplacement,... % closed-loop condition, where the azimuth is yoked to the wheel
    threshold.to(stimulusOff),  -response*abs(p.stimulusAzimuth)); % once threshold is reached, the stimulus is fixed again

%% define the visual stimulus

% LEFT STIMULUS
leftStimulus = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
leftStimulus.orientation = p.stimulusOrientation;
leftStimulus.altitude = 0;
leftStimulus.sigma = [9,9]; % in visual degrees
leftStimulus.spatialFreq = p.spatialFrequency; % in cycles per degree
leftStimulus.phase = map(evts.newTrial, @(x) 2*pi*rand);   % phase randomly changes each trial
leftStimulus.contrast = contrastLeft;
leftStimulus.azimuth = -p.stimulusAzimuth + azimuth;

% when show is true, the stimulus is visible
leftStimulus.show = stimulusOn.to(stimulusOff);

% store stimulus in visual stimuli set and log as 'leftStimulus'
vs.leftStimulus = leftStimulus; 

% RIGHT STIMULUS
rightStimulus = vis.grating(t, 'sinusoid', 'gaussian');
rightStimulus.orientation = p.stimulusOrientation;
rightStimulus.altitude = 0;
rightStimulus.sigma = [9,9];
rightStimulus.spatialFreq = p.spatialFrequency;
rightStimulus.phase = map(evts.newTrial, @(x) 2*pi*rand);
rightStimulus.contrast = contrastRight;
rightStimulus.azimuth = p.stimulusAzimuth + azimuth;
rightStimulus.show = stimulusOn.to(stimulusOff); 

% store stimulus in visual stimuli set
vs.rightStimulus = rightStimulus; 

%% end the trial and log events

% use the next set of conditional paramters only if positive feedback
% was given, or if the parameter 'Repeat incorrect' was set to false.
nextCondition = feedback > 0 | p.repeatIncorrect == false; 

% save these signals in the 'events' structure with appropriate names
evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.stimulusDisplacement = stimulusDisplacement;
evts.interactiveOn = interactiveOn;

% save the contrasts as a difference between left and right
evts.contrast = p.stimulusContrast.map(@diff); 

% save the stimulus's starting position
evts.azimuth = azimuth;

% save the mouse's response and the feedback given
evts.response = response;
evts.feedback = feedback;

% accumulate reward signals and append microliter units
evts.rewardSize = rewardSize;
evts.totalReward = out.reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl')); 

% trial ends when evts.endTrial updates  
% if the value of evts.endTrial is false, the current set of conditional
% parameters are used for the next trial. if evts.endTrial updates to true, 
% the next set of randomly picked conditional parameters is used. trial end
% is futher extended by an intertrial delay, if one is assigned
evts.endTrial = nextCondition.at(stimulusOff).delay(p.interTrialDelay); 

%% parameter defaults

try
p.onsetToneFrequency = 8000;
p.stimulusContrast = [1 0;0.5 0;0.25 0;0.12 0;0.07 0;0.05 0;0 0;...
        0 0.05;0 0.07;0 0.12;0 0.25;0 0.5;0 1]'; % conditional parameters have ncols > 1
p.repeatIncorrect = true;
p.audDevIdx;
p.audSampleRate = 48000;
p.onsetToneAmplitude = 0.2;
p.responseWindow = Inf;
p.stimulusAzimuth = 90;
p.noiseBurstAmp = 0.02;
p.noiseBurstDur = 0.5;
p.rewardSize = [2 2]';
p.rewardKey = 'r';
p.stimulusOrientation = 0;
p.spatialFrequency = 0.067; % Prusky & Douglas, 2004
p.interTrialDelay = 0.5;
p.encoderResolution = 100;
p.wheelGain = 5;
p.quiescenceThreshold = 10;
catch
end
end

















