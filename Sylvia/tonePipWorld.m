function tonePipWorld(t, evts, p, vs, inputs, outputs, audio)
%TONEPIPWORLD Summary of this function goes here
%   Detailed explanation goes here

% t: current time of the experiment

% evts: place where the important signals are kept (not all of them, but
% the trial "events" related ones >> essentially everything in this
% function is a signal
% example - every time you have a new trial, that's a new event >>
% evts.newTrial

% p: parameters - in gui, set up the parameters, and the gui knows
% automatically how many parameters it needs by looking at this function

% vs: where the visual stimuli live

% inputs: atm, wheel position
% outputs: atm, only reward
% audio: sends waveforms to soundcard

audioSR = 192e3; % fixed for now

numPinkNoiseSamples = audioSR*p.pinkNoiseDur;
pinkNoiseSamples = p.pinkNoiseAmplitude*numPinkNoiseSamples.map(@pinknoise);
% pinkNoise = map(p.pinkNoiseFalloff, p.pinkNoiseDur, );
audio.pinkNoise = pinkNoiseSamples.at(evts.newTrial);

% make some short names
wheel = inputs.wheel.skipRepeats();

%% when to display stimulus & allow it to move
onsetToneSamples = p.onsetToneAmplitude*...
    mapn(p.onsetToneFreq, p.onsetToneDuration, audioSR, p.onsetToneRampDuration, @aud.pureTone);
% onsetToneOn     = evts.newTrial.delay(p.onsetToneDelay);
audio.onsetTone = onsetToneSamples.at(evts.newTrial.delay(p.onsetToneDelay));

stimuliOn       = evts.newTrial.delay(p.onsetStimDelay);
interactiveOn   = stimuliOn.delay(p.interactiveDelay);

%% wheel position to stimulus displacement
wheelOrigin = wheel.at(interactiveOn);
targetDisplacement = p.wheelGain*(wheel - wheelOrigin); 

%% response at threshold detection
responseTimeOver = (t - t.at(interactiveOn)) > p.responseWindow;

threshold = interactiveOn.setTrigger(...
  abs(targetDisplacement) >= abs(p.targetAzimuth) | responseTimeOver);
% negative because displacement is opposite sign to initial position
response = cond(...
  responseTimeOver, 0,...
  true, -sign(targetDisplacement));   % response will be 0 when no go, -1 when left (azimuth = -30?) 1 when right
response = response.at(threshold);

%% feedback
% feedback =  sign(p.targetAzimuth.at(response))*response;
feedback = 2*(p.correctResponse == response)  - 1;
% creates new parameter that can be -1, 0 or 1 to denote the desired response
% the bit in the brackets looks at whether that is true, ie correct, in which case that equals 1, 
% or false, when the wrong response was made, in which case it equals 0
% by doing this operation, feedback will then take on the value of 1 when correct and -1 when incorrect
feedback = feedback.at(threshold);    
% we need to look at threshold as response can takevalue 0, which the code doesn't like - it expects a non-zero value
% feedback = feedback.at(response); 
audio.noiseBurst = at(p.noiseBurstAmp*p.noiseBurstDur.map(@(dur)randn(2,dur*audioSR)), feedback < 0);
reward = p.rewardSize.at(feedback > 0); 
outputs.reward = reward;

%% stimulus position
visStimOff = threshold.delay(cond(...
    feedback > 0, p.rewardDur, ...
    feedback < 0, p.noiseBurstDur));

azimuth = p.targetAzimuth + cond(...
  stimuliOn.to(interactiveOn), 0,... % no offset during fixed period
  interactiveOn.to(threshold), targetDisplacement,...%offset by wheel
  threshold.to(visStimOff),  -response*abs(p.targetAzimuth));

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
nextCondition = feedback > 0; % advance trial condition if correct, otherwise same gets repeated
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