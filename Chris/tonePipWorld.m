function tonePipWorld(t, evts, p, vs, inputs, outputs, audio)
%TONEPIPWORLD Summary of this function goes here
%   Detailed explanation goes here

audioSR = 192e3; % fixed for now

% make some short names
wheel = inputs.wheel.skipRepeats();

%% when to display stimulus & allow it to move
stimuliOn = evts.newTrial.delay(1);
interactiveOn = stimuliOn.delay(1);

%% wheel position to stimulus displacement
wheelOrigin = wheel.at(interactiveOn);
targetDisplacement = p.wheelGain*(wheel - wheelOrigin); 

%% response at threshold detection
threshold = interactiveOn.setTrigger(...
  abs(targetDisplacement) >= abs(p.targetAzimuth));
% negative because displacement is opposite sign to initial position
response = -sign(targetDisplacement.at(threshold));

%% feedback
feedback =  sign(p.targetAzimuth.at(response))*response;
audio.noiseBurst = p.noiseBurstAmp.map(@(a)a*randn(2,audioSR)).at(feedback < 0);
reward = p.rewardSize.at(feedback > 0); 
outputs.reward = reward;

%% stimulus position
visStimOff = response.delay(1);
azimuth = p.targetAzimuth + cond(...
  stimuliOn.to(interactiveOn), 0,... % no offset during fixed period
  interactiveOn.to(response), targetDisplacement,...%offset by wheel
  response.to(visStimOff),  -response*abs(p.targetAzimuth));

%% auditory stimulus
pipOff = threshold;
pipPlaying = stimuliOn.to(threshold);
freqPosition = p.pipHomeFreq*2.^(-0.5*p.pipFreqGain*azimuth/abs(p.targetAzimuth));
% todo: sample interval can be signal
sampler = skipRepeats(floor(p.pipRate*t)); % sampler will update at pipRate
pipFreq = freqPosition.at(sampler).keepWhen(pipPlaying);
pipSamples = p.pipAmplitude*mapn(...
  pipFreq, p.pipDuration, audioSR, p.pipRampDuration, @aud.pureTone);
audio.pips = pipSamples.keepWhen(pipPlaying);

%% misc
nextCondition = feedback > 0; % advance trial condition if correct
% 'endTrial' is a special event we create that will be used by the
% experiment to advance the trial
evts.endTrial = nextCondition.at(visStimOff);

% we want to save these so we put them in events with appropriate names
evts.stimuliOn = stimuliOn;
evts.pipOff = pipOff;
evts.interactiveOn = interactiveOn;
evts.pipFreq = pipFreq;
evts.response = response;
evts.feedback = feedback;
evts.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));

end