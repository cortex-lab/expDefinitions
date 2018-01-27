function audiovisWorld(t, evts, p, vs, inputs, outputs, audio)

audioSR = 192e3; % fixed for now

numPinkNoiseSamples = audioSR*p.pinkNoiseDur;
pinkNoiseSamples = p.pinkNoiseAmplitude*numPinkNoiseSamples.map(@pinknoise);
% pinkNoise = map(p.pinkNoiseFalloff, p.pinkNoiseDur, );
audio.pinkNoise = pinkNoiseSamples.at(evts.newTrial);

% make some short names
wheel = inputs.wheel.skipRepeats();

%% when to display stimulus & allow it to move
% inter-trial delay that gets taken from an exponential distribution
interTrialDelayEnd = evts.newTrial.delay(p.interTrialDelay.map(@(x)min(x(1) + exprnd(x(3)), x(2))));

onsetToneSamples = p.onsetToneAmplitude*...
  mapn(p.onsetToneFreq, p.onsetToneDuration, audioSR, p.onsetToneRampDuration, @aud.pureTone);
audio.onsetTone = onsetToneSamples.at(interTrialDelayEnd.delay(p.onsetCueDelay));   % delay the onsetTone by parameter in gui from end of interTrialDelay          
% audio.onsetTone = onsetToneSamples.at(evts.newTrial.delay(p.onsetCueDelay));

stimuliOn       = interTrialDelayEnd.delay(p.onsetStimDelay);       % delay the stimOnset by parameter in gui from end of interTrialDelay
% audStimOff      = evts.newTrial.delay(p.pipToneDuration); EJ test 10/09/2015
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
feedback = 2*(p.correctResponse == response)  - 1;
feedback = feedback.at(threshold);
audio.noiseBurst = at(p.noiseBurstAmp*p.noiseBurstDur.map(@(dur)randn(2,dur*audioSR)), feedback < 0);
reward = p.rewardSize.at(feedback > 0); 
outputs.reward = reward;

%% stimulus position
% EJ commented it out to make a general StimOff which can be tied to both visual and auditory stimuli
% visStimOff = threshold.delay(cond(...
%     feedback > 0, p.rewardDur, ...
%     feedback < 0, p.noiseBurstDur));

StimOff = threshold.delay(cond(...
  feedback > 0, p.rewardDur, ...
  feedback < 0, p.noiseBurstDur));
stimOff2 = threshold.delay(cond(...
  feedback > 0, p.rewardDur, ...
  feedback < 0, p.noiseBurstDur));  

% EJ addition 28/08/2015
visStimPresent = stimuliOn.to(stimOff2);

azimuth = p.targetAzimuth + cond(...
  stimuliOn.to(interactiveOn), 0,... % no offset during fixed period
  interactiveOn.to(threshold), targetDisplacement,...%offset by wheel
  threshold.to(StimOff),  -response*abs(p.targetAzimuth));

%% auditory stimulus
% EJ commented it out to hae general StmOff that applies to both visual and auditory stimuli, see above
% pipOff = threshold.delay(cond(...
%     feedback > 0, p.rewardDur, ...
%     feedback < 0, p.noiseBurstDur));
pipPlaying = stimuliOn.to(StimOff);
% pipPlaying = stimuliOn.to(audStimOff);
freqPosition = p.pipHomeFreq*2.^(-0.5*p.pipFreqGain*azimuth/abs(p.targetAzimuth));
% todo: sample interval can be signal
sampler = skipRepeats(floor(p.pipRate*t)); % sampler will update at pipRate
pipFreq = freqPosition.at(sampler).keepWhen(pipPlaying);
pipSamples = p.pipAmplitude*mapn(...
  pipFreq, p.pipDuration, audioSR, p.pipRampDuration, @aud.pureTone);
audio.pips = pipSamples.keepWhen(pipPlaying);

%% visual stimulus
vistarget = vis.grating(t, 'sinusoid', 'gaussian');
vistarget.altitude          = p.targetAltitude;
vistarget.sigma             = p.targetSigma;
vistarget.spatialFrequency  = p.targetSpatialFrequency;
vistarget.phase             = 2*pi*evts.newTrial.map(@(v)rand); % random phase on each trial
vistarget.orientation       = p.targetOrientation;
vistarget.contrast          = p.targetContrast;
vistargetAzimuth = p.targetAzimuth + cond(...
  stimuliOn.to(interactiveOn), 0,... % no offset during fixed period
  interactiveOn.to(threshold),   targetDisplacement,...%offset by wheel
  threshold.to(StimOff),    -response*abs(p.targetAzimuth));%final response
vistarget.azimuth           = vistargetAzimuth;
vistarget.show              = visStimPresent;
vs.target = vistarget; % put target in visual stimuli set

% onset cue stimulus
% keep all settings the same as for stimulus, apart from its own contrast value
viscue = vis.grating(t, 'sinusoid', 'gaussian');
viscue.altitude          = p.targetAltitude;
viscue.sigma             = p.targetSigma;
viscue.spatialFrequency  = p.targetSpatialFrequency;
viscue.phase             = 2*pi*evts.newTrial.map(@(v)rand); % random phase on each trial
viscue.orientation       = p.targetOrientation;
viscue.contrast          = p.cueContrast;
viscue.azimuth           = p.cueAzimuth;
viscue.show              = p.onsetCueDelay.to(stimOff2);
vs.cue = viscue;

%% misc
nextCondition = feedback > 0;
evts.endTrial = nextCondition.at(StimOff);

% we want to save these so we put them in events with appropriate names
evts.stimuliOn = stimuliOn;
evts.stimuliOff = StimOff;
evts.interactiveOn = interactiveOn;
evts.targetAzimuth = vistargetAzimuth;
evts.pipFreq = pipFreq;
evts.response = response;
evts.feedback = feedback;
evts.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));

end