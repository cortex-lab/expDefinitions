function testWorld(t, evts, p, vs, in, out, audio)
%% Very simple exp to test keyboard
% reward = evts.keyboard.strcmp(p.rewardKey);
% reward = reward.at(evts.newTrial.identity);
% reward = false;
% period = skipRepeats(floor(t*p.freq)/p.freq);
wheel = in.wheel.skipRepeats();
wheelOrigin = wheel.at(evts.newTrial);
w = wheel - wheelOrigin;

% out.reward = p.rewVol.at(reward);
test = evts.newTrial.then(wheel);
evts.endTrial = evts.newTrial.delay(10);
% evts.period = period;
% evts.reward = reward;
% evts.wheel = in.wheel;
evts.wheel = w;
evts.test = test;

%section to declare the default parameters 
try  
p.rewVol = 5;
p.rewardKey = 'r';
p.freq = 1/5;
catch
end
end