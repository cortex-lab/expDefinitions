function filmWorld(t, events, params, visStim, inputs, outputs, audio)% varargin)  % previously in place of visStim etc

% For testing purposes only:
%Screen('Preference', 'SkipSyncTests', 1);
%Screen('Preference', 'WindowShieldingLevel', 0);
% net = sig.Net;
% events = sig.Registry();
% events.expStart = net.origin('expStart');
% events.newTrial = net.origin('newTrial');
% events.trialNum = events.newTrial.scan(@plus, 0);
% events.expStart.post(1);
% events.newTrial.post(1);

% Define constants: 
% Get directory where movies are stored.
moviesDir =... 
  '\\zserver.cortexlab.net\Lab\Share\Tim\stimuli\merged_video';
% Number of movies in directory.
nMovies = 7;
% Interval (in s) between playing movies (for showing blank screen)
t_int = 0.1;
% Movie speed (1 = 1x)
playbackRate = 5;
% Number of times to loop each movie.
loop = 0;
% Number of times to repeat all movies in same randomly generated order (>=1).
repeats = 1;

% Select a random movie from a movies directory each new trial:
% Create a struct of the movies as a signal.
moviesStruct = events.expStart.map(@(~) dir(fullfile(moviesDir, '*.mp4')));
% Get index of movie within `movie_struct` randomly every trial.
idxs = events.expStart.map(@(~) randperm(nMovies));
movieIdx = iff(events.trialNum==0, 1, events.trialNum); %idxs(events.trialNum+1);
%movieIdx = events.newTrial.delay(0.1).then(idxs(events.trialNum+1));
% Get movie to play from `moviesStruct`, and set as a subscriptable signal
% so we can subscript its fields to get its full path.
curMovie = movieIdx.then(moviesStruct(movieIdx)).subscriptable();
curMovieFolder = curMovie.folder;
curMovieName = curMovie.name;
% Get full path of `curMovie`.
curMoviePath = curMovieName.map(@(~)...
  fullfile(curMovieFolder.Node.WorkingValue,... 
           curMovieName.Node.WorkingValue));

% Play movie: 
playingMovie = curMoviePath.delay(t_int).map(@(x)... 
  playMovie(x, playbackRate, loop));

% Create endTrial and expStop conditions:
events.endTrial = playingMovie.delay(0.1).then(1);
stop = playingMovie.then(events.trialNum == nMovies*repeats);
events.expStop = stop.then(1);

% Define signals to log in `events`
events.idxs = idxs;
events.movieIdx = movieIdx;
events.playingMovie = playingMovie;

  function [movieFinished] = playMovie(moviePath, playbackRate, loop)
    % Plays video
    % Arguments
    % loop: if >= 1, then loop, otherwise vidoe plays once.
    
    windowPtr = Screen('Windows');
    movie = Screen('OpenMovie', windowPtr, moviePath);
    
    if loop >= 1
      Screen('PlayMovie', movie, playbackRate, loop);
    else
      Screen('PlayMovie', movie, playbackRate);
    end
    
    while true % ~KbCheck or true
      
      % Wait for next movie frame, retrieve texture handle to it
      tex = Screen('GetMovieImage', windowPtr, movie);
      
      % Valid texture returned? A negative value means end of movie reached:
      if tex<=0
        % We're done, break out of loop:
        break;
      end
      
      % Draw the new texture immediately to screen:
      Screen('DrawTexture', windowPtr, tex);
      
      % Update display:
      Screen('Flip', windowPtr);
      % Release texture:
      Screen('Close', tex);
      
    end
    
    % close movie.
    Screen('CloseMovie', movie);
    % reset screen to background color.
    Screen('Flip', windowPtr);
    movieFinished = true;
    
  end

end