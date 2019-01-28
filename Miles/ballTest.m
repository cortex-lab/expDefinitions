%% Test script for the ball Signal using Cortexlab MouseBall software
% Function for testing the ball input in Signals, which uses UDP Websockets
% to listen for coordinates from the Cortexlab MouseBall software on port
% 9999.
%
% In the standard position of the device mouse A is on the east side, mouse
% B on the north side.
%
% According to the MouseBall Tracker application: 
% 
% - Ax goes positive if the ball turns away from mouse A, and negative if
%  the ball turns towards Mouse A.
% - Bx goes positive if the ball moves away from mouse B and negative if
% the ball moves towards mouse B.
% - Ay goes positive for counterclockwise and negative for clockwise
% rotation
% - By behaves in the same way.
%
% If mouse B is in front and mouse A is on the right hand (paw) side
% of the (real) mouse:
%
% mouse walks north: Bx goes positive
% mouse walks south: Bx goes negative
% mouse walks east:  Ax goes positive
% mouse walks west:  Ax goes negative
% mouse rotates the ball clockwise (turning left): Ay and By go positive
% mouse rotates the ball counterclockwise (turning right): Ay and By go negative

%% Set up the UDP socket and ball Signal
% Create new Signals network
net = sig.Net;
% Create an input Signal for posting the ball UDPs to
ballInput = net.origin('ball');
% Hostname of the remote computer running MouseBall software.  In a Signals
% Experiment this should be a global parameter called ballHostname
ballHost = 'ZBALL';
% Create our listener using the BallUDPService object
ballSocket = srv.BallUDPService(ballHost, ballInput);
% Derive a new Signal that allows us to subscript the ball Signal
ball = ballInput.subscriptable();
% Let's plot the resulting Signals
sig.timeplot(ball.time, ball.Ax, ball.Ay, ball.Bx, ball.By);
% Bind the Socket to start listening for UDPs
ballSocket.bind()

%% Simulation because I don't have a ball!
% To exit loop, simply press CTRL+C
looping = true;
while looping
  C = {now, rand, rand, rand, rand};
  [s.time, s.Ax, s.Ay, s.Bx, s.By] = deal(C{:});
  ballInput.post(s);
  pause(0.1) % Pause because my processor is weak
end

%% Cleanup
% Unbind the listener
delete(ballSocket); %#ok<UNRCH>