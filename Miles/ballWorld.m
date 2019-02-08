function ballWorld(t, evts, p, vs, in, out, audio)
%% Ball World
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

%% inputs
% The ball input is a subscriptable Signal containing the following
% Signals Ax, Bx, Ay, By and time
NS = skipRepeats(in.ball.Bx); % North-South Signal
EW = skipRepeats(in.ball.Ax); % East-West Signal
CW = skipRepeats(in.ball.Ay); % Clock-wise rotation Signal

southward = NS < 0; % a.k.a. backwards
northward = ~southward;

eastward = EW > 0;
westward = ~eastward;

leftward = CW > 0;

%% trial structure
% In order for any expDef to work, the endTrial event must be defined
evts.endTrial = evts.newTrial.delay(10);

%% events
% Define the events you wish to save here.  NB: all inputs are by default
% logged, so at the end of each experiment you will have a non-scalar
% struct in your block file called inputs.ball which will contain all
% UDPs received from the MouseBall host during the experiment.
evts.NS = NS;
evts.EW = EW;
p.ballHostname;

%% parameters
% In order for the UDP Websocket to be activated, a parameter called
% ballHostname must be present.  This parameter contains the hostname of
% the remote computer running MouseBall.
try
  p.ballHostname = 'ZBALL';
catch
end
