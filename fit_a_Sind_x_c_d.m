function [fitresult, gof] = fit_a_Sind_x_c_d(axis_angle, axis_value)
%CREATEFIT(AXIS_ANGLE,AXIS_VALUE)
%  Create a fit.
%
%  Data for 'untitled fit 1' fit:
%      X Input : axis_angle
%      Y Output: axis_value
%  Output:
%      fitresult : a fit object representing the fit.
%      gof : structure with goodness-of fit info.
%
%  另请参阅 FIT, CFIT, SFIT.

%  由 MATLAB 于 24-Oct-2021 17:02:00 自动生成


%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( axis_angle, axis_value );

% Set up fittype and options.
ft = fittype( 'a*sind(x+c)+d', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [0.546916481931513 0.724861444702151 0.262971284540144];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

% % Plot fit with data.
% figure( 'Name', 'untitled fit 1' );
% h = plot( fitresult, xData, yData );
% legend( h, 'axis_value vs. axis_angle', 'untitled fit 1', 'Location', 'NorthEast', 'Interpreter', 'none' );
% % Label axes
% xlabel( 'axis_angle', 'Interpreter', 'none' );
% ylabel( 'axis_value', 'Interpreter', 'none' );
% grid on


