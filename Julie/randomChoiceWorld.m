function randomChoiceWorld(t, evts, p, vs, inputs, outputs, audio)
numAudChannels = 2; %PC - need "numAudChannels" for signals to recognise? 
onsetToneFreq = p.onsetToneFrequency; %e.g. 3300?
rewardToneFreq = p.rewardToneFrequency; %e.g. 6600?
audSampleRate = 44100; %Check PTB Snd('DefaultRate'); previously: 96kHz
contrastLeft = p.targetContrast(1);
contrastRight = p.targetContrast(2);

stimulusOn = evts.newTrial;

onsetToneSamples = p.onsetToneAmplitude*...
    mapn(onsetToneFreq, 0.1, audSampleRate, 0.02, numAudChannels, @aud.pureTone); %aud.pureTone(freq, duration, samprate, "ramp duration", numAudChannels)
audio.onsetTone = onsetToneSamples.at(stimulusOn);

noiseBurstSamples = p.noiseBurstAmp*...
    mapn(numAudChannels, p.noiseBurstDur*audSampleRate, @randn);
audio.noiseBurst = noiseBurstSamples.at(feedback==0); 

rewardToneSamples = p.rewardToneAmplitude*...
    mapn(rewardToneFreq, 0.1, audSampleRate, 0.02, numAudChannels, @aud.pureTone);
audio.rewardTone = rewardToneSamples.at(feedback > 0);

targetLeft = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetLeft.orientation = p.targetOrientation;
targetLeft.altitude = 0;
targetLeft.sigma = [9,9];
targetLeft.spatialFrequency = p.spatialFrequency;
targetLeft.phase = 2*pi*evts.newTrial.map(@(v)rand);   %random phase
targetLeft.contrast = contrastLeft;
targetLeft.azimuth = -p.targetAzimuth + azimuth;
targetLeft.show = stimulusOn.to(stimulusOff);

vs.targetLeft = targetLeft;

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

evts.stimulusOn = stimulusOn;
% evts.stimulusOff = stimulusOff;
evts.contrast = p.targetContrast.map(@diff);
evts.azimuth = azimuth;
evts.endTrial = nextCondition.at(stimulusOff).delay(p.interTrialDelay);

% %% random world parameters
% trialLen = 1;
% 
% samplerFs = 60; %huh? 
% 
% onsetToneRate = 2;
% % rewardToneRate = 2;
% % noiseBurstRate = 2; 
% 
% % clickRate = 0.1; 
% 
% % stimRate = 0.09; %idk
% 
% %% event parameters
% %onset tone
% audSampleRate = 44100;
% onsetToneAmp = 0.1; %or whatever
% onsetToneFreq = 3300; %or whatever it is 
% % numAudChannels = 2; %true on ZMAZE
% 
% %noise burst
% % noiseBurstDur = 2;
% % noiseBurstAmp = 0.2; 
% % 
% % %reward tone
% % rewardToneFreq = 6600;
% % rewardToneAmp = 0.2; 
% 
% % %valve clicks/reward (if spout there) 
% % rewardSize = 3; % controls the duration of the pulse to the valve controller, obscurely
% 
% % %stimuli
% % stim = vis.grating(t, 'sinusoid', 'gaussian');
% % stim.orientation = 0; %or 90??
% % stim.altitude = 0;
% % stim.sigma = [9,9];
% % stim.spatialFrequency = 0.3; %or whatever
% % stim.phase = 2*pi*evts.newTrial.map(@(v)rand);   %random phase
% % stim.contrast = 0.5; %choose randomly
% % stim.azimuth = 30; %or 90, and closer to 0 
% 
% %% run a command at a certain sampling rate
% %skipRepeats is a \signals\+sig\+tranfer function
% %if rand met then plays various items 
% sampler = skipRepeats(floor(t*samplerFs)); 
% 
% 
% %% sounds 
% %signal.scan(f, seed) returns a new signal where its values result from
% %iteratively scanning each new value in signal through function f together
% %with the last resulting value. i.e. this allows you to create a signal
% %which iteratively updates based on the current value and each new piece of
% %information. seed defines the intial value of the result signal.
% onsetToneStart = skipRepeats(sampler.scan(@(x,y)rand()<onsetToneRate/samplerFs, 0));
% % noiseBurstStart = skipRepeats(sampler.scan(@(x,y)rand()<noiseBurstRate/samplerFs, 0));
% % rewardToneStart = skipRepeats(sampler.scan(@(x,y)rand()<rewardToneRate/samplerFs, 0));
% 
% onsetToneSamples = onsetToneAmp*...
%     mapn(onsetToneFreq, 0.1, audSampleRate, 0.02, @aud.pureTone); %aud.pureTone(freq, duration, samprate, "ramp duration", numAudChannels)
% audio.onsetTone = onsetToneSamples;
% 
% % noiseBurstSamples = noiseBurstAmp*...
% %     mapn(numAudChannels, noiseBurstDur*audSampleRate, @randn);
% % audio.noiseBurst = noiseBurstSamples; 
% % 
% % rewardToneSamples = rewardToneAmp*...
% %     mapn(rewardToneFreq, 0.1, audSampleRate, 0.02, numAudChannels, @aud.pureTone);
% % audio.rewardTone = rewardToneSamples;
% 
% 
% 
% % %% valve clicks
% % clickStart = skipRepeats(sampler.scan(@(x,y)rand()<clickRate/samplerFs, 0));
% % outputs.reward = clickStart*rewardSize;
% % 
% % %% gratings
% % 
% % %add diff contrasts 
% % stimStart = sampler.scan(@(x,y)rand()<stimRate/samplerFs, 0);
% % stimEnd = stimStart.delay(1/samplerFs);
% % 
% % stimOn = stimStart.to(stimEnd); %don't show stimuli simultaneously 
% % 
% % stim.show = stimOn; 
% % vs.stim = stim; %why? 
% 
% %% misc
% trialEnd = evts.newTrial.delay(trialLen);
% evts.endTrial = trialEnd; 
% 
% % we want to save these so we put them in events with appropriate names
% % evts.stimStart = stimStart; 
% % evts.stimuliTracker = stimuliTracker; %what 
% evts.sampler = sampler;
% evts.onsetToneStart = onsetToneStart;
% % evts.noiseBurstStart = noiseBurstStart;
% % evts.rewardToneStart = rewardToneStart;
% % evts.clickOnset = clickStart;
end


