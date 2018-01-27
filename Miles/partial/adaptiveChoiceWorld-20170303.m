function adaptiveChoiceWorld(t, evts, pars, visStim, in, out, audio)
%simpleChoiceWorld Basic movable grating experiment
%   Defines a task with a horizontally translatable grating stimulus that
%   is initially presented on each trial to the left or right. Centering
%   the stimulus yields a reward; moving it too far in the other
%   direction yields a noise burst. In either case it locks into the
%   threshold position during the feedback period.

% make some short names
p = pars;
wheel = in.wheel.skipRepeats();

%% when to present stimuli & allow visual stim to move
stimulusOn = evts.newTrial.delay(p.stimulusDelay);
interactiveOn = stimulusOn.delay(p.interactiveDelay);

%% wheel position to stimulus displacement
wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
targetDisplacement = p.wheelGain*(wheel - wheelOrigin); 

%% response at threshold detection
% responseTimeOver = (t - t.at(interactiveOn)) > p.responseWindow;
% threshold = interactiveOn.setTrigger(...
%     abs(targetDisplacement) >= abs(p.targetAzimuth) | responseTimeOver);
threshold = interactiveOn.setTrigger(abs(targetDisplacement) >= abs(p.targetAzimuth));
% negative because displacement is opposite sign to initial position
% response = cond(...
%     responseTimeOver, 0,...
%     true, -sign(targetDisplacement));
% response = -sign(targetDisplacement);
% response = response.at(threshold);
response = -sign(targetDisplacement.at(threshold));
biasSeed = response.bufferUpTo(10);
bias = biasSeed.map(@sum);
% bias = response.scan(@plus, 0); % bias is sum of responses (-1 right, 1 left, 0 no-go)
stimulusOff = response.map(true).delay(p.feedbackDuration);

%% target azimuth
az = bias.mapn(p.targetAzimuth, evts.trialNum, 'normal', @azimuthCalc).at(evts.newTrial);
if rand>0.5
    initialAzimuth = p.targetAzimuth.times(-1);
else
    initialAzimuth = p.targetAzimuth.times(1);
end
azimuth = cond(eq(evts.trialNum,1), initialAzimuth, gt(evts.trialNum,1), az);

%% feedback
feedback = sign(azimuth.at(response))*response; % positive or negative feedback
% 96KHz stereo noist burst waveform played at negative feedback
audio.noiseBurst = p.noiseBurstAmp.map(@(a)a*randn(2, 96e3)).at(feedback < 0);
out.reward = p.rewardSize.at(feedback > 0); % reward only on positive feedback

%% performance and contrast
initPerf = struct('testContrast', 1, 'contrasts', 1, 'totalCorrect', 0, 'totalTrials', 0);
perf = feedback.scan(@perfCalc, initPerf).subscriptable();
contrast = cond(eq(evts.trialNum,1), 1, gt(evts.trialNum,1), perf.testContrast);

target = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
target.altitude = p.targetAltitude;
target.sigma = p.targetSigma;
target.spatialFrequency = p.targetSpatialFrequency;
target.contrast = contrast.at(stimulusOn);
target.phase = 2*pi*evts.newTrial.map(@(v)rand);
targetAzimuth = azimuth + cond(... conditional
  stimulusOn.to(interactiveOn), 0,... % no offset during fixed period
  interactiveOn.to(response),   targetDisplacement,...%offset by wheel
  response.to(stimulusOff),    -response*abs(p.targetAzimuth));%final response
target.azimuth = targetAzimuth;
target.show = stimulusOn.to(stimulusOff);
visStim.target = target; % store target in visual stimuli set

%% misc
% we want to save these signals so we put them in events with appropriate names
nextCondition = feedback.map(true);
interTrialInterval = feedback.scan(@itiCalc, 0, 'pars', 0.5, 4);

evts.stimulusOn = stimulusOn;
evts.stimulusOff = stimulusOff;
evts.interactiveOn = interactiveOn;
evts.targetAzimuth = targetAzimuth;
evts.response = response;
evts.feedback = feedback;
evts.bias = bias;
evts.contrasts = perf.contrasts;
evts.endTrial = nextCondition.at(stimulusOff).delay(interTrialInterval.map2(0.05.*randn,@plus)); % 'endTrial' is a special event used to advance the trial

end
function iti = itiCalc(iti, feedback, delta, max)
%% Calculate new iti
if feedback == -1
    iti = iti + delta;
else % feedback = 1
    iti = iti - (delta*3); % reduce iti three times more
end

if iti < 0
  iti = 0;
elseif iti > max
  iti = max;
end
end    
function newAzimuth = azimuthCalc(bias, azimuth, trialNum, mode)
if trialNum<10||bias==0 % if number of trials is below 10 or no bias, 
    mode = 'none';      % then 50% chance of azimuth on either side
end
bias = bias/10; % bias normalized by trial number: abs(bias) = 0:1

switch mode
    case 'uniform'  % random number from uniform distribution 0:1
        r = rand - bias; % adjust liklihood r>0.5
    case 'normal'
        sd = 0.5; % standard deviation
        r = 0.5 + sd.*randn; % pull number from normal dist with mean 0.5
        r = r - bias; % shift distribution
    otherwise
        r = rand;   % random number from uniform distribution 0:1
end

if r>0.5
    newAzimuth=abs(azimuth); % if r>0.5, azimuth +ve, thus presented right
else
    newAzimuth=-abs(azimuth); % if r>0.5, azimuth -ve, thus presented left
end
end
function performance = perfCalc(performance, feedback)
%% Unpack struct
contSmpl = performance.contrasts;
cont = performance.testContrast;
totalCorrect = performance.totalCorrect;
totalTrials = performance.totalTrials;

%% Update performance data
idx = find(contSmpl==cont);
if isempty(idx)
    contSmpl = [contSmpl cont];
    idx = find(contSmpl==cont);
end

totalTrials(idx) = totalTrials(idx)+1;
if feedback == 1
    totalCorrect(idx) = totalCorrect(idx)+1;
end

%% Calculate performance
perf = totalCorrect./totalTrials;
perfCI = 1.96*sqrt(perf.*(1-perf)./totalTrials); % confidence interval
targ = 0.75 + 0.02*randn;

%% Adjust contrast pool
loCont = min(contSmpl);
loInc = contSmpl==loCont;
% add lower contrast if performance of lowest contrast trials > target
if perf(loInc)-perfCI(loInc)>targ...
        &&totalTrials(loInc)>10&&loCont>0.1
    contSmpl(end+1) = loCont / 2;
    contSmpl(end) = round(contSmpl(end)*1000)/1000;
    totalCorrect = [totalCorrect 0];
    totalTrials = [totalTrials 0];
end
% remove highest contrast if performance of top three contrasts > target
if sum(gt((perf-perfCI),targ))>2
    hiExl = contSmpl~=max(contSmpl);
    contSmpl = contSmpl(hiExl);
    totalCorrect = totalCorrect(hiExl);
    totalTrials = totalTrials(hiExl);
end

%% Repack variables into struct
performance.contrasts = contSmpl;
performance.totalTrials = totalTrials;
performance.totalCorrect = totalCorrect;
performance.testContrast = datasample(contSmpl,1); % Sample next test contrast from pool

end