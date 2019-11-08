function imageWorld2(t, evts, p, vs, ~, ~, ~)
% IMAGEWOLD Presentation of Marius's image set
%  Image directory must contain image files as MAT files named imgN where N
%  = {1, ..., N total images}.
%% Set some constants
% Image directory
%imgDir = '\\zserver.cortexlab.net\Data\pregenerated_textures\Marius\proc\selection101';
imgDir = p.imgDir.skipRepeats();
% Number of images in directory.
%nImgs = 5;
nImgs = imgDir.map(@file.list).map(@numel); % Get number of images
% Number of times to repeat each image in total
%repeats = 2;

%% define the visual stimulus
% The trial index given that we are using `events.trialNum` to index the
% images, and may want to repeat all movies more than once.
trialIdx = mod(evts.trialNum, nImgs) + 1;
imgIdxs = nImgs.map(@randperm).at(trialIdx == 1);
on = evts.newTrial.to(evts.newTrial.delay(p.onDuration));
off = at(true, on == false); % `then` makes sure off only ever updates to true
% If you want each image to repeat a set number of times...  Here when
% endTrial is false idx will update with the same value as before,
% repeating the image.
showNext = evts.repeatNum == p.repeats;
evts.endTrial = showNext.at(off).delay(p.offDuration);
% evts.endTrial = off.delay(p.offDuration); % Show each once

imgIdx = imgIdxs(trialIdx); 
imgIdxStr = imgIdx.map(@num2str);

% imgArr = imgDir.map2(imgIdxStr, ...
%   @(dir,num)loadVar(fullfile(dir, ['img' num '.mat']), 'img'));
imgArr = imgIdx.map2(imgDir, ...
  @(num,dir)loadVar(fullfile(dir, ['img', num2str(num), '.mat']), 'img'));

% Test stim left
%sourceImage = imgArr.map(@rescale);
%vs.stimulus = vis.image(t, sourceImage); % create a Gabor grating
vs.stimulus = vis.image(t);
vs.stimulus.sourceImage = imgArr.map(@rescale);
vs.stimulus.show = on;

%% End trial and log events
evts.stimulusOn = on;

% Session ends when all images shown.
stop = evts.trialNum == nImgs*p.repeats;
evts.expStop = stop.then(1);
evts.trialIdx = trialIdx;
evts.imgIdx = imgIdx;
evts.nImgs = nImgs;
evts.imgIdxs = imgIdxs;
evts.imgIdxStr = imgIdxStr;
evts.imgArr = imgArr;

%% Parameter defaults
% See timeSampler for full details on what values the *Delay paramters can
% take.  Conditional perameters are defined as having ncols > 1, where each
% column is a condition.  All conditional paramters must have the same
% number of columns.
try
  imgDir = '\\zserver.cortexlab.net\Data\pregenerated_textures\Marius\proc\selection101';
  p.imgDir = imgDir;
  p.onDuration = 5;
  p.offDuration = 2;
  p.repeats = 2; % Repeat each image twice in a row
catch 
  % NB At the start of a Signals experiment (as opposed to when you call
  % inferParameters) this catch block is executed.  Therefore you could
  % preload the images here during the initiazation phase.
  preLoad(imgDir);
end

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

function preLoad(imgDir)
% PRELOAD Load images into memory to speed up retrieval
%  The burgbox function `loadVar` caches the images it loads and so long as
%  the files have not been modified, will return the cached image rather
%  than re-loading from the disk.  Calling this function either at expStart
%  or independent of any signals will load all the images into memory
%  well before the stimuli are presented.  This may be useful if you want
%  to show them in quick succession.  
%
% See also loadVar, clearCBToolsCache

% Clear any previously cached images so that memory doesn't blow up
clearCBToolsCache % Comment out to keep images cached between experiments
imgs = dir(fullfile(imgDir, '*.mat')); % Get all images from directory
loadVar(strcat({imgs.folder},'\',{imgs.name})); % Load into memory
end

function img = rescale(img)
% RESCALE Rescales image from [-1 1] to [0 255]
img = max(img,-1); img = min(img, 1);
img = (img*128+128);
end