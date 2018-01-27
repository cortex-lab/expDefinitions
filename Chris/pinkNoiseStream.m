function pinkNoiseStream(t, evts, p, vs, inputs, outputs, audio)
%TONEPIPWORLD Summary of this function goes here
%   Detailed explanation goes here

audioSR = 192e3; % fixed for now

% time signal sampled every p.noiseChunkDuration
sampler = skipRepeats(floor(t));
audio.pinkNoise = p.noiseAmplitude*sampler.scan(@(~,~)1, 2).map(...
  @(n)pinknoise(n*audioSR));

evts.endTrial = evts.newTrial.delay(1);

end