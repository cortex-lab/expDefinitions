function audiovisWorldBigRig(t, evts, p, vs, inputs, outputs, audio)

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
audio.onsetTone = onsetToneSamples.at(evts.newTrial.delay(p.onsetToneDelay));

stimuliOn       = evts.newTrial.delay(p.onsetStimDelay);
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

stimOff = threshold.delay(cond(...
    feedback > 0, p.rewardDur, ...
    feedback < 0, p.noiseBurstDur));

% EJ addition 28/08/2015
visStimPresent = stimuliOn.to(stimOff);

azimuth = p.targetAzimuth + cond(...
  stimuliOn.to(interactiveOn), 0,... % no offset during fixed period
  interactiveOn.to(threshold), targetDisplacement,...%offset by wheel
  threshold.to(stimOff),  -response*abs(p.targetAzimuth));

%% auditory stimulus
% EJ commented it out to hae general StmOff that applies to both visual and auditory stimuli, see above
% pipOff = threshold.delay(cond(...
%     feedback > 0, p.rewardDur, ...
%     feedback < 0, p.noiseBurstDur));
pipPlaying = stimuliOn.to(stimOff);
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
vistarget.contrast          = p.contrast;
vistargetAzimuth = p.targetAzimuth + cond(...
  stimuliOn.to(interactiveOn), 0,... % no offset during fixed period
  interactiveOn.to(threshold), targetDisplacement,...%offset by wheel
  threshold.to(stimOff),    -response*abs(p.targetAzimuth));%final response
vistarget.azimuth           = vistargetAzimuth;
vistarget.show              = visStimPresent;
vs.target = vistarget; % put target in visual stimuli set

%% misc
nextCondition = feedback > 0;
% trialEnd      = stimOff + p.postTrialDelay;   % EJ test, or:
% trialEnd      = stimOff.delay(p.postTrialDelay);
% evts.endTrial = nextCondition.at(trialEnd);
evts.endTrial =  nextCondition.at(stimOff.delay(p.postTrialDelay));
% evts.endTrial = nextCondition.at(stimOff);

% we want to save these so we put them in events with appropriate names
evts.stimuliOn = stimuliOn;
evts.stimuliOff = stimOff;
evts.interactiveOn = interactiveOn;
evts.targetAzimuth = vistargetAzimuth;
evts.pipFreq = pipFreq;
evts.response = response;
evts.feedback = feedback;
evts.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));

%% Configure mpepdatahosts
acqTimeout = 10; % timeout for each trial acquisition
dataHosts = io.MpepUDPDataHosts({'zi'});
%dataHosts = io.MpepUDPDataHosts({'zamera2'});
dataHosts.DaqVendor = 'ni';
dataHosts.DaqDevId = 'Dev1';
dataHosts.DigitalOutDaqChannelId = 'Port0/Line0';
dataHosts.Verbose = true;
% dataHosts.Verbose = false;

listeners = [
  evts.expStart.onValue(@onStart);
%   evts.trialNum.delay(p.onsetAcquisitionDelay).onValue(@(trial)dataHosts.stimStarted(trial, acqTimeout)); %EJ test
  %evts.trialNum.delay(p.onsetStimDelay-1).onValue(@(trial)dataHosts.stimStarted(trial, acqTimeout));
  % evts.stimuliOff.onValue(@(~)dataHosts.stimEnded());
  evts.endTrial.onValue(@(~)dataHosts.stimEnded());
  evts.expStop.onValue(@onStop);
  ];

  function onStart(ref)
    disp('********** onStart **********');
    dataHosts.open;
    assert(all(dataHosts.ping), 'Could not ping all data acquistion hosts');
    dataHosts.ResponseTimeout = 30;
    dataHosts.expStarted(ref);
  end

  function onStop(~)
    disp('********** onStop **********');
    dataHosts.expEnded();
    dataHosts.close;
    listeners = [];
  end


end