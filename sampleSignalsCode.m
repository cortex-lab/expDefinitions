function sampleSignalsCode(t, evts, p, vs, inputs, outputs, audio)
%% example code that mostly follows conventions from ChoiceWorld, but with some naming changes agreed upon during the Coding Club 25/05/2016

% anything starting with p. will appear as a parameter in the gui
% anything within evts will be saved in the block structure

wheel = inputs.wheel.skipRepeats(); %input from wheel with skipped repeats.

% These exact paramaters below must be included if you want to use a unique
% auditory ouput. The defaults are 2 channels, 196kHz, and []
p.numAudChannels;
p.audSampleRate;
p.audDevIdx;

%% ITI & pre-stim quiescent period
% inter-trial delay that gets taken from an exponential distribution, 
% during which no quiescence is required
interTrialDelayEnd  = evts.newTrial.delay(p.interTrialDelay.map(@rnd.uni));
% syntax explanation: 
% interTrialDelay is given by p.interTrialDelay, which is drawn from a
% random uniform distribution with min and max defined as arguments in p.interTrialDelay
% (this could be changed to any other form of distribution, if desired:
% this would be achieved by changed the map(@...) argument)
% and newTrial (start) is delayed by the time given by interTrialDelay

% quiescent period to initiate trial, also mapped using exponential distribution
% if animal moves during this period, it gets reset
preStimPeriod       = p.preStimQuiescentPeriod.at(interTrialDelayEnd).map(@rnd.uni);
% syntax explanation:
% preStimPeriod starts at interTrialDelayEnd, and the during of this period
% is drawn from a random uniform distribution in this case
% (could again be changed to some other distribution if desired)

%% onset cues and stimulus presentations
% cue that signals upcoming stimulus, appears after the end of the preStim quiescent period
% this only defines the timing of it; visual or auditory properties to be further defined
stimCueOn       = sig.quiescenceWatch(preStimPeriod, t, wheel, p.quiescThreshold);

% define auditory properties of stimCue
onsetToneSamples = p.stimCueToneAmplitude*...
  mapn(p.stimCueToneFreq, p.stimCueToneDuration, audioSR, p.stimCueToneRampDuration, @aud.pureTone);
audio.onsetTone = onsetToneSamples.at(stimCueOn);
% if wanted to define visual onset cue; see example of visual interactive cue

stimuliOn        = stimCueOn.delay(p.onsetStimDelay); 
% define period during which the stimulus must be kept still using exponential distribution
stimQuiescPeriod = p.stimQuiescentPeriod.at(stimuliOn).map(@(x)min(x(1) + exprnd(x(3)), x(2)));

% define timing of the cue that tells animals when they can give a response
interactiveCueOn            = sig.quiescenceWatch(stimQuiescPeriod, t, wheel, p.quiescThreshold); 

% auditory interactive cue parameters
interactiveToneSamples = p.interactiveToneAmplitude*...
  mapn(p.interactiveToneFreq, p.interactiveToneDuration, audioSR, p.interactiveToneRampDuration, @aud.pureTone);
audio.interactiveTone = interactiveToneSamples.at(interactiveCueOn);         
% visual cue parameters defined within the visual stimuli section

% define timepoint from which onwards wheel movement is coupled to stimulus
interactiveOn   = interactiveCueOn.delay(p.interactiveDelay);

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

%% vis stimulus position

stimOff = threshold.delay(cond(...
  feedback > 0, p.rewardDur, ...
  feedback < 0, p.noiseBurstDur));
stimOff2 = threshold.delay(cond(...
  feedback > 0, p.rewardDur, ...
  feedback < 0, p.noiseBurstDur));            
% used for the cue stimulus determination:
% when the trial is wrong, the visual cue in the middle disappears after 0.1 seconds rather than staying for p.noiseBurstDur
stimOff3 = threshold.delay(cond(...
  feedback > 0, p.rewardDur, ...
  feedback < 0, 0.1));            
% EJ addition 28/08/2015
stimPresent = stimuliOn.to(stimOff3);

azimuth = p.targetAzimuth + cond(...
  stimuliOn.to(interactiveOn), 0,... % no offset during fixed period
  interactiveOn.to(threshold), targetDisplacement,...%offset by wheel
  threshold.to(stimOff3),  -response*abs(p.targetAzimuth));

%% auditory stimulus

% pipPlaying = stimuliOn.to(StimOff);
freqPosition = p.pipHomeFreq*2.^(-0.5*p.pipFreqGain*azimuth/abs(p.targetAzimuth));
% todo: sample interval can be signal
sampler = skipRepeats(floor(p.pipRate*t)); % sampler will update at pipRate
pipFreq = freqPosition.at(sampler).keepWhen(stimPresent);
pipSamples = p.pipAmplitude*mapn(...
  pipFreq, p.pipDuration, audioSR, p.pipRampDuration, @aud.pureTone);
audio.pips = pipSamples.keepWhen(stimPresent);

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
  threshold.to(stimOff),    -response*abs(p.targetAzimuth));%final response
vistarget.azimuth           = vistargetAzimuth;
vistarget.show              = stimuliOn.to(stimOff2);  
vs.target = vistarget; % put target in visual stimuli set

% visual cue parameters
% keep all settings the same as for stimulus, apart from its own contrast value
viscue = vis.grating(t, 'sinusoid', 'gaussian');
viscue.altitude          = p.targetAltitude;
viscue.sigma             = p.targetSigma;
viscue.spatialFrequency  = p.targetSpatialFrequency;
viscue.phase             = 2*pi*evts.newTrial.map(@(v)rand); % random phase on each trial
viscue.orientation       = p.targetOrientation;
viscue.contrast          = p.cueContrast;
viscue.azimuth           = p.cueAzimuth;
viscue.show              = interactiveCueOn.to(stimOff3);
vs.cue = viscue;

%% misc
nextCondition = feedback > 0 | evts.repeatNum >= p.maxRepeatNum;
% nextCondition = feedback > 0;
evts.endTrial = nextCondition.at(stimOff);

% we want to save these so we put them in events with appropriate names
evts.stimCueOn      = stimCueOn;
evts.interactStimCueOn = interactiveCueOn;
evts.stimuliOn      = stimuliOn;
evts.stimuliOff     = stimOff;
evts.interactiveOn  = interactiveOn;
evts.targetAzimuth  = vistargetAzimuth;
evts.pipFreq        = pipFreq;
evts.response       = response;
evts.feedback       = feedback;
evts.totalReward    = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));

end