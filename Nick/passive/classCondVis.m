function classCondVis(t, evts, p, vs, inputs, outputs, audio)


%% parameters

% flashes
fullFieldSize = [270 90]; % covers the whole screen

% beeps
beepFreq = p.beepFrequency*evts.newTrial;
audioSR = 192e3; 

% valve clicks
rewardSize = 3.5; % controls the duration of the pulse to the valve controller, obscurely


%% beeps
beepOnset = evts.newTrial; %start the beep at trial onset

toneSamples = p.beepAmplitude*... % to turn it off, set beepAmplitude=0
  mapn(beepFreq, p.beepDur*2, audioSR, 0.02, @aud.pureTone);
audio.tone = toneSamples.at(beepOnset);


%% visual flashes
flashOnset = evts.newTrial; %start the flash at trial onset too
flashOffset = flashOnset.delay(p.flashDur); % to turn it off, set flashDur=0

flashOn = flashOnset.to(flashOffset);

fullField = vis.patch(t, 'rect');
fullField.dims = fullFieldSize;
fullField.show = flashOn*(p.flashDur>0); %make sure it doesn't even show for one frame if flashDur==0
vs.fullField = fullField;

%% puffs
clickOnset = evts.newTrial.delay(p.puffDelay); % airpuff happens after specified delay
outputs.reward = clickOnset*rewardSize;

%% misc
trialEnd = evts.newTrial.delay(p.trialLenMin+rand(1)*(p.trialLenMax-p.trialLenMin));
evts.endTrial = trialEnd; 

% we want to save the timing of these so we put them in evts with appropriate names
evts.beepOnset = beepOnset;
evts.clickOnset = clickOnset;
evts.flashOn = flashOn;
end


