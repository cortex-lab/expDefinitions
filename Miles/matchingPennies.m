function matchingPennies(t, evts, p, vs, in, out, audio)
%% Matching Pennies
% https://www.sciencedirect.com/science/article/pii/S0926641004001971#aep-section-id23
% https://www.sciencedirect.com/science/article/pii/S0092867414011076?via%3Dihub#sec4

%% parameters
wheel = in.wheel.skipRepeats(); % skipRepeats means that this signal doesn't update if the new value is the same of the previous one (i.e. if the wheel doesn't move)

%% when to present stimuli & allow visual stim to move
preStimulusDelay = p.preStimulusDelay.map(@timeSampler).at(evts.newTrial); % at(evts.newTrial) fix for rig pre-delay 
stimulusOn = sig.quiescenceWatch(preStimulusDelay, t, wheel, floor(p.encoderRes/100));
interactiveDelay = p.interactiveDelay.map(@timeSampler);
interactiveOn = stimulusOn.delay(interactiveDelay); % the closed-loop period starts when the stimulus comes on, plus an 'interactive delay'

audioDevice = audio.Devices('default');
onsetToneSamples = p.onsetToneAmplitude*...
    mapn(p.onsetToneFrequency, 0.1, audioDevice.DefaultSampleRate,...
    0.02, audioDevice.NrOutputChannels, @aud.pureTone); % aud.pureTone(freq, duration, samprate, "ramp duration", nAudChannels)
audio.default = onsetToneSamples.at(interactiveOn); % At the time of 'interative on', send samples to audio device and log as 'onsetTone'

%% wheel position to stimulus displacement
% Here we define the multiplication factor for changing the wheel signal
% into mm/deg visual angle units.  The Lego wheel used has a 31mm radius.
% The standard KÜBLER rotary encoder uses X4 encoding; we record all edges
% (up and down) from both channels for maximum resolution. This means that
% e.g. a KÜBLER 2400 with 100 pulses per revolution will actually generate
% *400* position ticks per full revolution.
wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
millimetersFactor = map2(p.wheelGain, 31*2*pi/(p.encoderRes*4), @times); % convert the wheel gain to a value in mm/deg
stimulusDisplacement = millimetersFactor*(wheel - wheelOrigin); % yoke the stimulus displacment to the wheel movement during closed loop

%% define response and response threshold 
responseTimeOver = (t - t.at(interactiveOn)) > p.responseWindow; % p.responseWindow may be set to Inf
threshold = interactiveOn.setTrigger(...
  abs(stimulusDisplacement) >= abs(p.stimulusAzimuth) | responseTimeOver);

response = cond(...
    responseTimeOver, 0,... % if the response time is over the response = 0
    true, -sign(stimulusDisplacement)); % otherwise it should be the inverse of the sign of the stimulusDisplacement

response = response.at(threshold); % only update the response signal when the threshold has been crossed
stimulusOff = threshold.delay(1); % true a second after the threshold is crossed

responseBuffer = response.scan(@horzcat, []); % Infinite buffer of values
algorithm = 2; % algorithm to use: TODO make signal
correctSide = responseBuffer.scan(@updateTrialData, randsample([-1 1],1), 'pars', algorithm, N);

%% define correct response and feedback
% each trial randomly pick -1 or 1 value for use in baited (guess) trials
newStim = iff(~mod(evts.trialNum,6) | evts.trialNum==1, true, false);
correctResponse = newStim.then(randsample([1 -1],1));
feedback = correctSide == response;
% Only update the feedback signal at the time of the threshold being crossed
feedback = feedback.at(threshold).delay(0.1); 

noiseBurstSamples = p.noiseBurstAmp*...
    mapn(audioDevice.NrOutputChannels, p.noiseBurstDur*audioDevice.DefaultSampleRate, @randn);
audio.default = noiseBurstSamples.at(feedback==0); % When the subject gives an incorrect response, send samples to audio device and log as 'noiseBurst'

reward = merge(rewardKeyPressed, feedback > 0);% only update when feedback changes to greater than 0, or reward key is pressed
out.reward = p.rewardSize.at(reward); % output this signal to the reward controller

%% stimulus azimuth
azimuth = cond(...
    stimulusOn.to(interactiveOn), 0,... % Before the closed-loop condition, the stimulus is at it's starting azimuth
    interactiveOn.to(threshold), stimulusDisplacement,... % Closed-loop condition, where the azimuth yoked to the wheel
    threshold.to(stimulusOff),  -response*abs(p.stimulusAzimuth)); % Once threshold is reached the stimulus is fixed again

%% define the visual stimuli

leftStimulus = vis.patch(t, 'circle');
leftStimulus.dims = [10,10];
leftStimulus.colour = [0 1 0];
leftStimulus.azimuth = -p.azimuth;
leftStimulus.show = true;
vs.left = leftStimulus;

rightStimulus = vis.patch(t, 'circle');
rightStimulus.dims = [10,10];
rightStimulus.colour = [0 1 0];
rightStimulus.azimuth = -p.azimuth;
rightStimulus.show = true;
vs.right = rightStimulus;

% Plus stimulus
cross = vis.patch(t, 'plus'); % create a Gabor grating
cross.dims = [10,10]; % in visual degrees
cross.show = stimulusOn.to(stimulusOff);
vs.plus = cross; % store stimulus in visual stimuli set and log as 'leftStimulus'

%%
% Cell array of visual stimuli
stimSet = struct2cell(vs); 
% Determine number of stimuli availiable
nStim = length(stimSet);
% Randomly select two indicies, but only do so when the newStim signal
% is true
selector = map(@()randsample(1:nStim,2));
selector = selector.at(newStim);

% Define when the stimuli should be visible, here we choose to show the
% stimuli when ever their index is selected
for i = 1:length(stimSet)
    stimSet{i}.show = any(selector == i);
    stimSet{i}.azimuth = cond(...
        selector(1) == i, -p.stimulusAzimuth + azimuth,...
        selector(2) == i, p.stimulusAzimuth + azimuth,...
        true, 0);
end

%% End trial and log events
% Let's use the next set of conditional paramters only if positive feedback
% was given, or if the parameter 'Repeat incorrect' was set to false.
nextCondition = feedback > 0 | p.repeatIncorrect == false; 

% we want to save these signals so we put them in events with appropriate
% names:
evts.stimulusOn = stimulusOn;
evts.preStimulusDelay = preStimulusDelay;
% save the contrasts as a difference between left and right
evts.contrast = p.stimulusContrast.map(@diff); 
evts.contrastLeft = contrastLeft;
evts.contrastRight = contrastRight;
evts.azimuth = azimuth;
evts.response = response;
evts.feedback = feedback;
evts.interactiveOn = interactiveOn;
% Accumulate reward signals and append microlitre units
evts.totalReward = out.reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl')); 

% Trial ends when evts.endTrial updates.  
% If the value of evts.endTrial is false, the current set of conditional
% parameters are used for the next trial, if evts.endTrial updates to true, 
% the next set of randowmly picked conditional parameters is used
evts.endTrial = nextCondition.at(stimulusOff).delay(p.interTrialDelay.map(@timeSampler)); 

%% Parameter defaults
% See timeSampler for full details on what values the *Delay paramters can
% take.  Conditional perameters are defined as having ncols > 1, where each
% column is a condition.  All conditional paramters must have the same
% number of columns.
try
c = [1 0.5 0.25 0.12 0.06 0];
%%% Contrast starting set
% C = [1 0;0 1;0.5 0;0 0.5]';
%%% Contrast discrimination set
% c = combvec(c, c);
% C = unique([c, flipud(c)]', 'rows')';
%%% Contrast detection set
C = [c, zeros(1, numel(c)-1); zeros(1, numel(c)-1), c];
p.stimulusContrast = C;
p.repeatIncorrect = abs(diff(C,1)) > 0.25 | all(C==0);
p.onsetToneFrequency = 5000;
p.interactiveDelay = 0.4;
p.onsetToneAmplitude = 0.15;
p.responseWindow = Inf;
p.stimulusAzimuth = 90;
p.noiseBurstAmp = 0.01;
p.noiseBurstDur = 0.5;
p.rewardSize = 3;
p.rewardKey = 'r';
p.stimulusOrientation = [0, 0]';
p.spatialFrequency = 0.19; % Prusky & Douglas, 2004
p.interTrialDelay = 0.5;
p.wheelGain = 5;
p.encoderRes = 1024;
p.preStimulusDelay = [0 0.1 0.09]';
catch % ex
%    disp(getReport(ex, 'extended', 'hyperlinks', 'on'))
end

%% Helper functions
function duration = timeSampler(time)
% TIMESAMPLER Sample a time from some distribution
%  If time is a single value, duration is that value.  If time = [min max],
%  then duration is sampled uniformally.  If time = [min, max, time const],
%  then duration is sampled from a exponential distribution, giving a flat
%  hazard rate.  If numel(time) > 3, duration is a randomly sampled value
%  from time.
%
% See also exp.TimeSampler
  if nargin == 0; duration = 0; return; end
  switch length(time)
    case 3 % A time sampled with a flat hazard function
      duration = time(1) + exprnd(time(3));
      duration = iff(duration > time(2), time(2), duration);
    case 2 % A time sampled from a uniform distribution
      duration = time(1) + (time(2) - time(1))*rand;
    case 1 % A fixed time
      duration = time(1);
    otherwise % Pick on of the values
      duration = randsample(time, 1);
  end
end
end

function correctSide = updateTrialData(correctSide, responses, algorithm, N)
    % https://www.sciencedirect.com/science/article/pii/S0926641004001971#aep-section-id23
switch algorithm
    case 0
        % In algorithm 0, the computer selected one of the two targets randomly
        % each with 50% probability. In matching pennies, this mixed strategy
        % corresponds to the Nash equilibrium. If one of the players plays
        % according to the equilibrium strategy in matching pennies, the expected
        % payoffs to both players are fixed regardless of the other player's
        % strategy. Therefore, this algorithm was employed to examine the initial
        % strategy of the animal before more exploitative algorithms described
        % below were introduced.
        newSide = randsample([-1 1], 1);
    case 1
        % In algorithm 1, the computer stored the entire sequence of
        % choices made by the animal in a given daily session. In each
        % trial, the computer then used this information to calculate the
        % conditional probabilities that the animal would choose each
        % target given the animal's choices in the preceding N trials (N=0
        % to 4). A null hypothesis that this probability is 0.5 was tested
        % for each of these conditional probabilities (binomial test,
        % p<0.05). If none of these hypotheses was rejected, it was assumed
        % that the animal had selected both targets with equal
        % probabilities independently from its previous choices, and the
        % computer selected its targets randomly as in algorithm 0. If one
        % or more hypotheses were rejected, then the computer biased its
        % target selection using the conditional probability with the
        % largest deviation from 0.5 that was statistically significant.
        % This was achieved by selecting, with the probability of 1?p, the
        % target that the animal had selected with the probability of p.
        % For example, if the animal had selected the right-hand target
        % with 80% probability, the computer would select the same target
        % with 20% probability. In algorithm 1, therefore, the animal was
        % required to select the two targets with equal probabilities and
        % independently from its previous choices, in order to maximize its
        % total reward.
        recent_responses = responses(end-N:end);
        prev_responses = [];
        maxInd = length(responses) - len;
        
        for i=1:maxInd
          if all(responses(i:i+N-1) == recent_responses)
            prev_responses = [prev_responses responses(i+N)];
          end
        end
        
        %responses = randsample([-1 1],100,true);
        choseLeft = sum(prev_responses) == -1;
        pout_L = myBinomTest(choseLeft, numel(prev_responses), .5, 'one'); % Thanks to Matthew Nelson for function
        % if isempty(prev_responses) || 
%         pout_R = myBinomTest(N-choseLeft,N,.5,'one'); 
        
    case 2
        rewarded = correctSide == responses;
end
correctSide = [correctSide newSide];
end