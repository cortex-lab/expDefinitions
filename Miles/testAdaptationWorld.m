function testAdaptationWorld(t, evts, p, vs, in, out, audio)
%% parameters
wheel = in.wheel.skipRepeats();
% nAudChannels = 2;
% audSampleRate = 196e3;
contrastLeft = p.targetContrast(1);
contrastRight = p.targetContrast(2);
% 
% %% when to present stimuli & allow visual stim to move
% adapterOn = evts.newTrial;
% adapterOff = adapterOn.delay(...
%     cond(evts.trialNum < 2, p.initialAdaptTime, true, p.interTrialAdaptTime));
stimulusOn = evts.newTrial.delay(0.3);
% interactiveOn = stimulusOn.delay(p.interactiveDelay);
% 
% onsetToneSamples = p.onsetToneAmplitude*...
%     aud.pureTone(10500, 0.1, audSampleRate, 0.02, 2);
% audio.onsetTone = onsetToneSamples.at(interactiveOn);
% 
% %% wheel position to stimulus displacement
wheelOrigin = wheel.at(stimulusOn); % wheel position sampled at 'interactiveOn'
targetDisplacement = p.wheelGain*(wheel - wheelOrigin); 
% 
% %% response at threshold detection
% responseTimeOver = (t - t.at(interactiveOn)) > p.responseWindow;
% threshold = interactiveOn.setTrigger(...
%   abs(targetDisplacement) >= abs(p.targetAzimuth) | responseTimeOver);
% % response = -sign(targetDisplacement);
% response = cond(...
%     responseTimeOver, 0,...
%     true, -sign(targetDisplacement));
% response = response.at(threshold);
stimulusOff = stimulusOn.delay(20);
% 
% %% feedback
% feedback = 2*(sign(p.targetAzimuth) == response)  - 1;
% feedback = feedback.at(threshold);
% audio.noiseBurst = p.noiseBurstAmp.map(...
%   @(a)a*randn(nAudChannels,audSampleRate)).at(feedback < 0);
% reward = p.rewardSize.at(feedback > 0); 
% out.reward = reward;
% 
% %% target azimuth
azimuth = p.targetAzimuth + targetDisplacement;
% azimuth = p.targetAzimuth + t.at(stimulusOn);

%% performance and contrast
% Adapter
phaseChange = skipRepeats(floor(t*5)/5);
% adapter = vis.grating(t, 'sinusoid', 'none'); % create a full field grating
% adapter.orientation = p.gratingOrient;
% adapter.spatialFrequency = p.spatialFrequency;
% adapter.phase = 2*pi*phaseChange.map(@(v)rand);
% adapter.contrast = 1;
% adapter.show = adapterOn.to(adapterOff);
% vs.adapter = adapter;

% Test stim left
targetLeft = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetLeft.orientation = 90;
targetLeft.altitude = 0;
targetLeft.sigma = [9,9];
targetLeft.spatialFrequency = 0.01;
targetLeft.phase = 2*pi*phaseChange.map(@(v)rand);
targetLeft.contrast = contrastLeft;
% targetLeft.azimuth = azimuth; % doesn't work
targetLeft.azimuth = azimuth;
targetLeft.show = stimulusOn.to(stimulusOff);

vs.targetLeft = targetLeft; % store target in visual stimuli set

% Test stim right
targetRight = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
targetRight.orientation = 90;
targetRight.altitude = 0;
targetRight.sigma = [9,9];
targetRight.spatialFrequency = 0.01;
targetRight.phase = 2*pi*phaseChange.map(@(v)rand);
targetRight.contrast = contrastRight;
targetRight.azimuth = -azimuth;
targetRight.show = stimulusOn.identity.to(stimulusOff);

vs.targetRight = targetRight; % store target in visual stimuli set

%% misc
% nextCondition = feedback > 0;
% nextCondition = true;
% nextCondition = feedback > 0 | evts.repeatNum > 9;

% we want to save these signals so we put them in events with appropriate names
% evts.adapterOn = adapterOn;
% evts.adapterOff = adapterOff;
evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.azimuth = azimuth;
% evts.response = response;
% evts.feedback = feedback;
% evts.performance = ;
% evts.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));
evts.endTrial = stimulusOff.delay(1);

end