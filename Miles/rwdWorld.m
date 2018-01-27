function rwdWorld(t, evts, p, vs, in, out, audio)
%% Very simple exp to test inferParams
% stimulusOn = evts.newTrial.delay(p.stimulusDelay);
stimOn = evts.newTrial.delay(p.interTrialDelay);
stimOff = stimOn.delay(1);


reward = p.rewardSize.at(stimOn).delay(0.5);
% p.laserOnsetDelays; %1x2 vector corresponding to bounds of a uniform distribution (e.g. [-0.3, 0.3] ) 
% laserOnsetDelay = at( p.laserOnsetDelays.map(@(x) x(1) + (x(2)-x(1))*rand) , evts.newTrial); %Draw a random delay
% TTL = true.at(evts.newTrial.delay(p.interTrialDelay + laserOnsetDelay) ); %TTL on at new trial + fixed delay + laserOnsetDelay

% stim = vis.grating(t, 'sinusoid', 'gaussian');
% stim.show = stimOn.to(stimOff);
% vs.stim = stim;

out.reward = reward;
% out.digitalTTL = TTL.to(TTL.delay(0.01));

evts.endTrial = evts.newTrial.delay(5);
evts.stimOn = stimOn;
evts.reward = reward;
% evts.TTL = TTL;
% evts.onsetDelays = laserOnsetDelay;
end