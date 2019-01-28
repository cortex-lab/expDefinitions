function imageWorld(t, evts, p, vs, ~, ~, ~)
%% IMAGEWORLD
% Image directory must contain image files as MAT files named imgN where N
% = {1, ..., N total images}.
%% parameters
% Image directory
imgDir = p.imgDir.skipRepeats();
N = imgDir.map(@(p)length(dir(fullfile(p,'*.mat')))); % Get number of images
imgIds = N.map(@randperm);

% preLoad;

%% define the visual stimulus
on = t.Node.Net.origin('on');
off = t.Node.Net.origin('off');
t.Node.Listeners = [t.Node.Listeners, ...
  on.delay(p.onDuration.map(@timeSampler)).into(off),...
  off.delay(p.offDuration.map(@timeSampler)).into(on),...
  into(map(evts.expStart, @ischar), on)];

idx = merge(map(evts.expStart, @ischar), evts.newTrial.scan(@plus, 0).at(off));
number = imgIds(idx);%.map(@num2str);
numberStr = number.map(@num2str);

% Test stim left
stimulus = vis.image(t, 'none'); % create a Gabor grating
stimulus.sourceImage = imgDir.map2(numberStr, ...
  @(dir,num)loadVar(fullfile(dir, ['img' num '.mat']), 'img'));
% stimulus.sourceImage = iff(evts.newTrial==1, ...
%   map(p.one, @(v)loadVar(v, 'img')), ...
%   map(p.two, @(v)loadVar(v, 'img')));
stimulus.show = on.to(off);

vs.stimulus = stimulus; % store stimulus in visual stimuli set and log as 'leftStimulus'

%% End trial and log events
% Let's use the next set of conditional paramters only if positive feedback
% was given, or if the parameter 'Repeat incorrect' was set to false.
evts.stimulusOn = on;

% Trial ends when evts.endTrial updates.  
% If the value of evts.endTrial is false, the current set of conditional
% parameters are used for the next trial, if evts.endTrial updates to true, 
% the next set of randowmly picked conditional parameters is used
evts.endTrial = idx==N; 
evts.index = idx;
evts.numStr = numberStr;
%% Parameter defaults
% See timeSampler for full details on what values the *Delay paramters can
% take.  Conditional perameters are defined as having ncols > 1, where each
% column is a condition.  All conditional paramters must have the same
% number of columns.
try
p.imgDir = '\\zserver.cortexlab.net\Data\pregenerated_textures\Marius\proc\selection2800';
p.one = '\\zserver.cortexlab.net\Data\pregenerated_textures\Marius\proc\selection2800\img1.mat';
p.two = '\\zserver.cortexlab.net\Data\pregenerated_textures\Marius\proc\selection2800\img2.mat';
p.onDuration = 5;
p.offDuration = 2;
catch ex
   disp(getReport(ex, 'extended', 'hyperlinks', 'on'))
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
  function preLoad()
    d = '\\zserver.cortexlab.net\Data\pregenerated_textures\Marius\proc\selection2800';
    imgs = dir(fullfile(d,'*.mat'));
    loadVar(strcat({imgs.folder},'\',{imgs.name}))
  end
end