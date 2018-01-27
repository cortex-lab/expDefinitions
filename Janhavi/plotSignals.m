


function f = plotSignals(figHand, signalRegistry)
%fprintf(1, 'trying to plot\n')
f = true;
% get the current time and current values immediately
thisTime = GetSecs();
%disp(logs(signalRegistry,0));
sigNames = fieldnames(signalRegistry);
%sigNames
nSig = length(sigNames);
sigLogs = logs(signalRegistry,get(figHand, 'UserData')); % the figure user data was the initialization time, so logs will be zeroed to that
save('C:\Users\Janhavi\Documents\MATLAB\signals-master\evts_values','sigLogs');
% uncomment this to check that values are coming in properly -
% for nn = 1:nSig
%     newVals{nn} = signalRegistry.(sigNames{nn}).Node.CurrValue;
% end
% for nn = 1:nSig
%     if ~isempty(newVals{nn})
%         fprintf(1, '%s = %d; ', sigNames{nn}, newVals{nn}(1));
%     end
% end
% fprintf(1, '\n');


% now set display parameters
dispWindowTime = 10; %seconds

% get the existing axis and lines
spAx = get(figHand, 'Children');
flag1 = false;
if isempty(spAx)
    flag1 =true;
    % store initialization time for later
    set(figHand, 'UserData', GetSecs());
    
    spAx = zeros(1,nSig);
    for nn = 1:nSig
        spAx(nn) = subplot(nSig,1,nn);
    end
    
elseif length(spAx)~= nSig
    fprintf(1, 'too many subplots\n')
    return
end


% for each signal, update the lines showing its value with the new current
% value
bslTime = get(figHand, 'UserData');
thisTime = thisTime-bslTime;
% disp(nSig);
try
for nn = 1:nSig
    
    t = sigLogs.([sigNames{nn} 'Times']);
    v = sigLogs.([sigNames{nn} 'Values']);
%     disp('bye');
%     disp(t);
%     disp(v);
%     disp('hello');
    if(size(t,2)==1 || size(t,2)==0)
        if(flag1)
            flag = false;
        else
            flag = true;
        end
    elseif(t(1,end)== t(1,end-1))
        flag =true;
    else
        flag = false;
    end      
            

    
%     disp(t);
%     disp(v);
    inclT = t>(thisTime-dispWindowTime);
%     disp(inclt);
    if ~isempty(t) && ~any(inclT)
        inclT(end) = true; % include the last point in the plotting if the previous last one is off the graph now
    end        
    
    if ~isempty(v)
        
        t = t(inclT);
       v = v(inclT); 
%         
         if ~isempty(v)
           t(end+1) = thisTime+1; % add one more point off the right edge of the plot so the current value extends
           v(end+1) = v(end);
% %             disp(sigNames{nn} );
% %             disp(v(end));
% %             disp(t(end));
         

%             if(~flag)
%                disp(t);
%                disp(v);
             hold(spAx(nn), 'on');
%             disp(t);
%             disp(v);
             plot(spAx(nn), t(1:end-1), v(1:end-1), '-ro');
            hold(spAx(nn), 'on');
            stairs(spAx(nn), t, v, 'Color', 'blue');
        
           
%             end
            
           
             

            vRange = max(v)-min(v);
            if vRange>0
                ylim(spAx(nn), [min(v)-0.1*vRange max(v)+0.1*vRange]);
            end
        
            xlim(spAx(nn), [thisTime-dispWindowTime thisTime]);
            ylabel(spAx(nn),sigNames{nn});
        end
    end
end
catch ex
    warning(ex.getReport());
end
end


