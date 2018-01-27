function randomWorld2(t, evts, p, vs, inputs, outputs, audio)


%% parameters
trialLen = 1;

% sparse noise
stimPersistence = 10/60;
stimulusRate = 0.09;
samplerFs = 60;
nAz = 9;
nAl = 33;

% flashes
flashRate = 0.5; %Hz
fullFieldSize = [270 90];

% beeps
beepRate = 2;
% beepFreq = 6000*evts.newTrial;
maxFreq = 20000; minFreq = 500;
beepDur = 0.1;
beepAmplitude = 0.2;
audioSR = 96000; % fixed for now

% valve clicks
clickRate = 0.1;
rewardSize = 3.5; % controls the duration of the pulse to the valve controller, obscurely


sampler = skipRepeats(floor(t*samplerFs)); % to run a command at a certain sampling rate


%% beeps

beepOnset = skipRepeats(sampler.scan(@(x,y)rand()<beepRate/samplerFs, 0));

beepFreq = beepOnset.scan(@(x,y)rand()*(maxFreq-minFreq)+minFreq,0);
toneSamples = beepAmplitude*...
  mapn(beepFreq, beepDur, audioSR, 0.02, @aud.pureTone);
% audio.tone = toneSamples.at(beepOnset);
audio.tone = toneSamples;

%% valve clicks
clickOnset = skipRepeats(sampler.scan(@(x,y)rand()<clickRate/samplerFs, 0));
outputs.reward = clickOnset*rewardSize;

%% visual flashes

flashOnset = sampler.scan(@(x,y)rand()<flashRate/samplerFs, 0);
% flashOnset = beepOnset;
flashOffset = flashOnset.delay(1/samplerFs);

flashOn = flashOnset.to(flashOffset);

fullField = vis.patch(t, 'rect');
fullField.dims = fullFieldSize;
fullField.show = flashOn;
vs.fullField = fullField;

%% visual sparse noise

stimuliTracker = sampler.scan(...
  @sparseNoiseTrackBW, ...
  zeros(nAz, nAl), 'pars', stimPersistence, stimulusRate, samplerFs);
% stimuliOn = skipRepeats(stimuliTracker > 0);
% stimuliOn = skipRepeats(sign(stimuliTracker));
stimuliOn = skipRepeats((stimuliTracker>0)*2-1);

myNoise = vis.checker4(t);
myNoise.pattern = stimuliOn;
myNoise.show = flashOffset.to(flashOnset); % opposite of flashes. So checker disappears while flashes happen. 
vs.myNoise = myNoise;




%% misc
trialEnd = evts.newTrial.delay(trialLen);
evts.endTrial = trialEnd; 

% we want to save these so we put them in events with appropriate names
evts.stimuliOn = stimuliOn; 
evts.stimuliTracker = stimuliTracker;
evts.sampler = sampler;
evts.beepOnset = beepOnset;
evts.beepFreq = beepFreq;
evts.clickOnset = clickOnset;
evts.flashOnset = flashOnset;
end


