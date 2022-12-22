function fitFormula = convertAtomPred(AtomPred)
% This function converts an atomic predicate into a function that evaluates
% the fitness value corresponding to the Atomic Predicate.
%
%           fitFormula = convertAtomPred(AtomPred)
%
%   E.g.:   fitFormula = convertAtomPred('x<=70')
%
% Input:
%   AtomPred: character array containing the Atomic Predicate in the form
%   of an equality or inequality.
%
% Output:
%   fitFormula: character array containing the formula that express the
%   fitness value of the given Atomic Predicate.

splitPred = regexp(AtomPred, '^([\s\S]+?)([<>=~]+)([\s\S]+?)$', 'tokens');
splitPred = splitPred{1};
sign = splitPred{2};
switch sign
    case {'<', '<='}
        fitFormula = [splitPred{3},'-(',splitPred{1},')'];
    case {'>', '>='}
        fitFormula = [splitPred{1},'-(',splitPred{3},')'];
    case '=='
        fitFormula = ['-1*(',AtomPred,')+abs(',splitPred{1},'-(',splitPred{3},'))'];
    case '~='
        fitFormula = ['-1+1*(',AtomPred,')-abs(',splitPred{1},'-(',splitPred{3},'))'];
    otherwise
        error('The operator %s in the verify statement is not supported.',sign)
end

end