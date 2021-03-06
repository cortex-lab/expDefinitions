function tutorial_pong(t, events, pars, visStim, inputs, outputs, audio)
% Pong: the final project for the tutorial

% This is a good example actually of impossible co-dependencies: the ball
% depends on the computer paddle (to hit it), but the computer paddle needs
% information about the ball (to move towards it). This is impossible. 
%
% Here's the way we solve this: group all computer-controlled altitudes
% together in one structure, update both at the same time
%
% WHERE THIS IS CURRENTLY BROKEN: 
% this is actually lot harder than expected: the balls velocity and
% position have to be signals themselves because they're dependent on other
% signals (namely the position of the player paddle altitude)

%% Set up the wheel 

wheel = inputs.wheel.skipRepeats;

%% Set up update clock

t_update_mod = 0.01; % how often to update the position
t_update = skipRepeats(t - mod(t,t_update_mod));

%% Visual stim

%%%% PADDLE PARAMETERS
paddle_altitude_initial = 0;
paddle_size = [5,40];
player_paddle_azimuth = 160;
computer_paddle_azimuth = -160;

%%%% PLAYER PADDLE
player_paddle_altitude = wheel.delta.scan(@paddle_boundary,paddle_altitude_initial);

player_paddle = vis.patch(t,'rectangle');
player_paddle.azimuth = player_paddle_azimuth;
player_paddle.altitude = cond( ...
    events.expStart,player_paddle_altitude, ...
    true, 0);
player_paddle.dims = paddle_size;
player_paddle.show = true;

%%%% COMPUTER POSITIONS
% (need to group ball and paddle because they are co-dependent: this means
% that they need to be updated simultaneously)
game_data_initial.ball_position = [0,0];
game_data_initial.ball_velocity = sign(rand(1,2) - 0.5).*[3,rand*3];
game_data_initial.computer_paddle_position = [computer_paddle_azimuth,paddle_altitude_initial];
game_data_initial.computer_paddle_speed = 2;
game_data_initial.player_paddle_azimuth = player_paddle_azimuth;
game_data_initial.paddle_size = paddle_size;

game_data = player_paddle_altitude.at(t_update).scan(@update_game_data,game_data_initial).subscriptable;

%%%% BALL
ball_size = [5,5];

ball = vis.patch(t,'rectangle');
ball.azimuth = game_data.ball_position(1);
ball.altitude = game_data.ball_position(2);
ball.dims = ball_size;
ball.show = true;

%%%% COMPUTER PADDLE
computer_paddle = vis.patch(t,'rectangle');
computer_paddle.azimuth = computer_paddle_azimuth;
computer_paddle.altitude = game_data.computer_paddle_position(2);
computer_paddle.dims = paddle_size;
computer_paddle.show = true;

%%%% SEND VISUAL COMPONENTS TO STIM HANDLER
visStim.player_paddle = player_paddle;
visStim.computer_paddle = computer_paddle;
visStim.ball = ball;

%% Define events to save

events.endTrial = events.newTrial.delay(5);

end

function player_paddle_altitude = paddle_boundary(player_paddle_altitude,wheel)

player_paddle_altitude = player_paddle_altitude + wheel;
if player_paddle_altitude > 90
    player_paddle_altitude = 90;
elseif player_paddle_altitude < -90
    player_paddle_altitude = -90;
end

end

function game_data = update_game_data(game_data,player_paddle_altitude)

% Define the border along the top: reverse ball altitude velocity
if abs(game_data.ball_position(2)) >= 90
    game_data.ball_velocity(2) = -game_data.ball_velocity(2);
end

% Define the border to hit paddles: reverse ball azimuth velocity
if ...
        (game_data.ball_position(1) <= game_data.computer_paddle_position(1) && ...
        game_data.ball_position(2) <= game_data.computer_paddle_position(2)+(game_data.paddle_size(2)/2) && ...
        game_data.ball_position(2) >= game_data.computer_paddle_position(2)-(game_data.paddle_size(2)/2)) || ...
        (game_data.ball_position(1) >= game_data.player_paddle_azimuth && ...
        game_data.ball_position(2) <= player_paddle_altitude+(game_data.paddle_size(2)/2) && ...
        game_data.ball_position(2) >= player_paddle_altitude-(game_data.paddle_size(2)/2))
    
    game_data.ball_velocity(1) = -game_data.ball_velocity(1);
    
end

if abs(game_data.ball_position(1)) >= 180
    game_data.ball_position = [0,0];
    game_data.ball_velocity = sign(rand(1,2) - 0.5).*[3,rand*3];
end

% Update the ball position
game_data.ball_position = game_data.ball_position + game_data.ball_velocity;

% Update the computer paddle altitude
game_data.computer_paddle_position(2) = game_data.computer_paddle_position(2) + ...
    game_data.computer_paddle_speed*sign(game_data.ball_position(2) - game_data.computer_paddle_position(2));

end











