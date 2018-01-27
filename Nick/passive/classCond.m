function classCond(t, evts, p, vs, inputs, outputs, audio)


%% parameters
% trialLen = 1;
trialLenMin = 5; 
trialLenMax = 15;

% sparse noise
% stimPersistence = 10/60;
% stimulusRate = 0.09;
% nAz = 9;
% nAl = 33;

% flashes
% flashRate = 0.5; %Hz
% fullFieldSize = [270 90];

% beeps
beepRate = 0.1;
beepFreq = 6000*evts.newTrial;
% beepFreq = 15000; 
beepDur = 4;
beepAmplitude = 1;
audioSR = 192e3; % fixed for now

% valve clicks
% clickRate = 0.1;
rewardSize = 3.5; % controls the duration of the pulse to the valve controller, obscurely

tonePuffDelay = 4.3;

samplerFs = 60;
sampler = skipRepeats(floor(t*samplerFs)); % to run a command at a certain sampling rate


%% beeps

% beepOnset = skipRepeats(sampler.scan(@(x,y)rand()<beepRate/samplerFs, 0));
beepOnset = evts.newTrial;

% beepFreq = beepOnset.scan(@(x,y)rand()*(maxFreq-minFreq)+minFreq,0);
toneSamples = beepAmplitude*...
  mapn(beepFreq, beepDur*2, audioSR, 0.02, @aud.pureTone);
audio.tone = toneSamples.at(beepOnset);
% audio.tone = toneSamples;

%% valve clicks
% clickOnset = skipRepeats(sampler.scan(@(x,y)rand()<clickRate/samplerFs, 0));
clickOnset = beepOnset.delay(tonePuffDelay);
outputs.reward = clickOnset*rewardSize;

%% visual flashes

% flashOnset = sampler.scan(@(x,y)rand()<flashRate/samplerFs, 0);
% % flashOnset = beepOnset;
% flashOffset = flashOnset.delay(1/samplerFs);
% 
% flashOn = flashOnset.to(flashOffset);
% 
% fullField = vis.patch(t, 'rect');
% fullField.dims = fullFieldSize;
% fullField.show = flashOn;
% vs.fullField = fullField;

%% visual sparse noise

% stimuliTracker = sampler.scan(...
%   @sparseNoiseTrackBW, ...
%   zeros(nAz, nAl), 'pars', stimPersistence, stimulusRate, samplerFs);
% % stimuliOn = skipRepeats(stimuliTracker > 0);
% % stimuliOn = skipRepeats(sign(stimuliTracker));
% stimuliOn = skipRepeats((stimuliTracker>0)*2-1);
% 
% myNoise = vis.checker4(t);
% myNoise.pattern = stimuliOn;
% myNoise.show = flashOffset.to(flashOnset); % opposite of flashes. So checker disappears while flashes happen. 
% vs.myNoise = myNoise;




%% misc
% trialEnd = evts.newTrial.delay(trialLen);
trialEnd = evts.newTrial.delay(trialLenMin+rand(1)*(trialLenMax-trialLenMin));
evts.endTrial = trialEnd; 

% we want to save these so we put them in events with appropriate names
% evts.stimuliOn = stimuliOn; 
% evts.stimuliTracker = stimuliTracker;
evts.sampler = sampler;
evts.beepOnset = beepOnset;
evts.beepFreq = beepFreq;
evts.clickOnset = clickOnset;
% evts.flashOnset = flashOnset;
end


