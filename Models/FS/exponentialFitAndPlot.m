function dRatio = exponentialFitAndPlot(n,rn)
%coder.extrinsic('message','warning','fittype','fit')
%EXPONENTIALFITANDPLOT    Fits expotential model to data

n = n(:);
rn = rn(:);

% --- Create fit "fit 1"
ok_ = isfinite(n) & isfinite(rn);
if ~all( ok_ )
    warning(message('RptgenSL:rptgen_sl:ignoringNansAndInfs'));
end
st_ = [0.49752506416553999 ]; %start value
ft_ = fittype('exp(d*n)',...
    'dependent',{'rn'},'independent',{'n'},...
    'coefficients',{'d'});

% Fit this model using new data
cf_ = fit(n(ok_),rn(ok_),ft_,'Startpoint',st_);

% Or use coefficients from the original fit:
if 0
    cv_ = { 0.42991383675518463};
    cf_ = cfit(ft_,cv_{:});
end

% Get fitting coefficient
delta = cf_.d';

% Compute damping ratio
dRatio = delta/sqrt((2*pi)^2+delta^2);

end