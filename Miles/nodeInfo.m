  function info = nodeInfo(varargin)
%   persistent level
%   if ~isobject(varargin{end})
%     level = varargin{end};
%     varargin(end) = [];
%   else
%     level = 0;
%   end
  
    info = struct;
    for n = 1:length(varargin)
      if isa(varargin{n},'sig.node.Node')
        node = varargin{n};
      else
        info(n).varName = inputname(n); %FIXME
        node = varargin{n}.Node;
      end
      info(n).Id = node.Id;
      info(n).Name = node.Name;
      if ~isempty(node.DisplayInputs)
        info(n).Inputs = [node.DisplayInputs.Id];
        info = catStructs([{info}, mapToCell(@nodeInfo,node.DisplayInputs)]);
      end
    end
  end
