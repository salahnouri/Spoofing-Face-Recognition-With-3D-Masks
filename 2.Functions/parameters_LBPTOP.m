%% PARAMETERS_LBPTOP
%  Function used to compute the best parameters for the LBP-TOP features
%  it uses grid.py taken from libsvm and csv2libsvm.py
%  OUTPUT:
%         - c    : the best c parameter from the development set
%         - gamma: the best gamma parameter from the development set

function [c,gamma] = parameters_LBPTOP( )
disp('---------------------');
disp('Parameters estimation');
disp('---------------------');

folder = '..\3.Results\c.features\lbp-top\';
out = '..\3.Results\d.libsvm_features\';

load([folder,'dev_data']);
load([folder,'dev_groups']);

% convert to double
devg = dev_groups;
dev_groups = zeros(length(dev_groups),1);
for i = 1:(length(dev_groups))
    if devg(i,:) == 'fake'
        dev_groups(i) = 0;
    else
        dev_groups(i) = 1;
    end
end
% save the features in csv format
dev_features = double(dev_features);
dev = cat(2,dev_groups,dev_features);
csvwrite([out,'dev_data_lbptop.csv'],dev);

% convet the features to libsvm format
command = ['python parameters_estimation\csv2libsvm.py '...
    out 'dev_data_lbptop.csv '...
    out 'out_lbptop.data '...
    '0 False'];
system(command);

% find the best combination of the parameters 'c' and 'gamma'
command = ['python parameters_estimation\grid.py '...
    '-svmtrain "parameters_estimation\svm-train.exe" '...
    '-gnuplot "parameters_estimation\gnuplot\bin\gnuplot.exe" '...
    '-log2c -20,20,2 -log2g -20,20,2 -v 9 '...
    out 'out_lbptop.data'];
[~,cmdout] = system(command);

% extract parameters c and gamma
out = regexp(cmdout,'[0-9]+\.[0-9]+(e(+|-)[0-9]+)?','match');
c = str2double(cell2mat(out(1)));
gamma = str2double(cell2mat(out(2)));
disp(['c     = ' cell2mat(out(1))]);
disp(['gamma = ' cell2mat(out(2))]);
end