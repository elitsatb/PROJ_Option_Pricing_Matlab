[folder, name, ext] = fileparts(which( mfilename('fullpath')));
cd(folder);


addpath('../RN_CHF')
addpath('../Helper_Functions')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Bermudan OPTION PRICER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Descritpion: Script to Price Bermudan/American options in Levy Models
%              using the PROJ method
% Author:      Justin Kirkby
% References:  (1) American and exotic option pricing with jump diffusions and other Levy Processes,
%               J. Compuational Finance, 2018
%              (2) Efficient Option Pricing By Frame Duality with The Fast
%              Fourier Transform, SIAM J. Financial Math., 2015

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  CONTRACT/GENERAL PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S_0  = 100;  %Initial price
W    = 100;  %Strike            %NOTE: no error handling in place for extreme values of W (increase grid if strike falls outside)
r    = .05;  %Interest rate
q    = .00;  %dividend yield
T    = 1;    %Time (in years)
M    = 12;  %number of discrete monitoring points

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model = 1;   %See Models Below (e.g. model 1 is Black Scholes), and choose specific params
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  CHOOSE PROJ PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
UseCumulant = 1;  %Set to 1 to use the cumulant base rule (Approach 1) to determine gridwidth, else used fixed witdth (Approach 2)

%---------------------
% APPROACH 1: Cumulant Based approach for grid width
% (see "Robust Option Pricing with Characteritics Functions and the BSpline Order of Density Projection")
%---------------------
if UseCumulant ==1  %With cumulant based rule, choose N and Alpha (N = 2^(P+Pbar) based on second approach)
    logN  = 12;   %Uses N = 2^logN  gridpoint 
    L1 = 12;  % determines grid witdth (usually set L1 = 8 to 15 for Levy, or 18 for Heston)
%---------------------
% APPROACH 2: Manual GridWidth approach 
%--------------------- 
else %Manually specify resolution and Pbar
    P     = 7;  % resolution is 2^P
    Pbar  = 3;  % Determines density truncation grid with, 2^Pbar 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  CHOOSE MODEL PARAMETERS 
%%%  Note: rnCHF is the risk netural CHF, c1,c2,c4 are the cumulants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
params = {};

if model == 1 %BSM (Black Scholes Merton)
    params.sigmaBSM = 0.15;    %CHOOSE   
    
elseif model == 2 %CGMY
    params.C  = 0.02; 
    params.G  = 5; 
    params.MM = 15; 
    params.Y  = 1.2;

elseif model == 3 %NIG
    params.alpha = 15;
    params.beta  = -5;
    params.delta = 0.5;
    
elseif model == 4 %MJD (Merton Jump Diffusion)
    params.sigma  = 0.12;
    params.lam    = 0.4;
    params.muj    = -0.12;
    params.sigmaj = 0.18;
    
elseif model == 5 %Kou Double Expo
    params.sigma = 0.15;
    params.lam   = 3;
    params.p_up  = 0.2;
    params.eta1  = 25;
    params.eta2  = 10;
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRICE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
modelInput = getModelInput(model, T/M, r, q, params);

if UseCumulant ==1  % Choose density truncation width based on cumulants
    alpha = getTruncationAlpha(T, L1, modelInput, model);
else    % Manually supply density truncation width above
    logN = P + Pbar;
    alpha = 2^Pbar/2;
end
N = 2^logN;    % grid roughly centered on [c1 - alph, c1 + alph]

tic
price = Bermudan_PUT_func_alpha(M, S_0, W, r, T, modelInput.rnCHF, N, alpha); 
toc


fprintf('%.8f \n', price)
