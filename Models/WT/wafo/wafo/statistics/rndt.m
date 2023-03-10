function R = rndt(varargin)
%RNDT  Random matrices from a Student's T distribution
%
% CALL:  R = rndt(dfn,sz)
%
%        R = matrix of random numbers
%       df = degrees of freedom
%       sz = size(R)    (Default size(df))
%            sz can be a comma separated list or a vector 
%            giving the size of R (see zeros for options)
%
% The random numbers are generated by the inverse method. 
%
% Examples:
%   R  = rndt(1,1,100);
%   R2 = rndt(1:10);
%   R3 = rndt(4,[2 2 3]);
%  
% See also  pdft,  cdft, invt, fitt, momt


% Tested on: Matlab 5.3
% History: 
% revised pab 23.10.2000
%  - added comnsize + nargchk
%  - added greater flexibility on the sizing of R
%       Anders Holtsberg, 18-11-93
%       Copyright (c) Anders Holtsberg
%
%     This program is free software; you can redistribute it and/or modify
%     it under the terms of the GNU Lesser General Public License as published by
%     the Free Software Foundation; either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU Lesser General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.



%error(nargchk(1,inf,nargin))
narginchk(1,inf)
Np = 1;
options = struct; % default options
[params,options,rndsize] = parsestatsinput(Np,options,varargin{:});
if numel(options)>1
  error('Multidimensional struct of distribution parameter not allowed!')
end

df = params{1};


if isempty(rndsize)
 csize = size(df);
else
  csize = comnsize(df,zeros(rndsize{:}));
  if any(isnan(csize))
    error('df must be a scalar or of corresponding size as given by m and n.');
  end
end
R = invt(rand(csize),df);



