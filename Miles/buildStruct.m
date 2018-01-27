function [structure] = buildStruct(varargin)
%BUILDSTRUCT Creates a structure from n number of signals
% 
varargin = fliplr(varargin);
structure = struct(varargin{:});
% if mod(nargin,2)
%     error('Must be even number of variables: n*(value, fieldName)');
% end
% 
% for i=1:2:nargin-1
%     structure.(varargin{i+1})=varargin{i};
% end
end