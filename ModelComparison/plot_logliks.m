% included for completeness, all chatGPT generated; not used for
% publication just checking as we go
load('model_comparisons.mat','model_comparisons');
% 
% included for completeness, all chatGPT generated; not used for
% publication just checking as we go
load('model_comparisons.mat','model_comparisons');

model_order = {'AlphaSM','AlphaSME','AlphaSMP','AlphaSMEP', ...
               'BayesSM','BayesSME','BayesSMP','BayesSMEP'};

cats = {'All Og','All Grouped','PreTreat','PostTreat','PostTreat Liv','PostTreat Dun','HC'};

% some reds, blues, greens and purples 
% alpha_cols = [0.98 0.82 0.82; 0.95 0.65 0.65; 0.90 0.48 0.48; 0.78 0.33 0.33];
% bayes_cols = [0.82 0.88 0.98; 0.64 0.78 0.95; 0.47 0.65 0.90; 0.32 0.53 0.80];
alpha_cols = [0.82 0.98 0.82; 0.65 0.95 0.65; 0.48 0.90 0.48; 0.33 0.78 0.33];
bayes_cols = [0.88 0.82 0.98; 0.78 0.64 0.95; 0.65 0.47 0.90; 0.53 0.32 0.80];
model_colors = [alpha_cols; bayes_cols];
%% ===== LPT (per trial)
BIC=model_comparisons.BIC;

Y = zeros(numel(cats), numel(model_order));
for mi = 1:numel(model_order)
    m = model_order{mi};
    Y(1,mi) = BIC.groups_original.(m).LPT_total;      % All Og
    Y(2,mi) = BIC.groups_grouped.(m).LPT_total;       % All Grouped
    Y(3,mi) = BIC.PreTreat.(m).LPT_total;             % Pre
    Y(4,mi) = BIC.PostTreat.(m).LPT_total;            % Post
    Y(5,mi) = BIC.PostTreat_Liv.(m).LPT_total;        % Post LV
    Y(6,mi) = BIC.PostTreat_Dun.(m).LPT_total;        % Post Dundee
    Y(7,mi) = BIC.HC.(m).LPT_total;                   % HC
end

figure('Color','w','Name','Likelihood Per Trial');
ax = axes; b = bar(Y,'grouped'); box off; grid on; hold on
for mi = 1:numel(model_order)
    b(mi).FaceColor = model_colors(mi,:);
    b(mi).EdgeColor = 'none';
end
set(ax,'XTick',1:numel(cats),'XTickLabel',cats,'XTickLabelRotation',20)
ylabel(ax,'LPT (per trial)')
title(ax,'Likelihood Per Trial: all groups')
lg = legend(model_order,'Location','eastoutside','Box','off'); lg.Title.String = 'Models';

%% ===== PSIS-LOO (per trial) 
psis_loo = model_comparisons.psis_loo;

Y = zeros(numel(cats), numel(model_order));
for mi = 1:numel(model_order)
    m = model_order{mi};
    Y(1,mi) = psis_loo.groups_original.(m).ELPD_per_trial_total;  % All Og
    Y(2,mi) = psis_loo.groups_grouped.(m).ELPD_per_trial_total;   % All Grouped
    Y(3,mi) = psis_loo.PreTreat.(m).ELPD_per_trial_total;         % Pre
    Y(4,mi) = psis_loo.PostTreat.(m).ELPD_per_trial_total;        % Post
    Y(5,mi) = psis_loo.PostTreat_Liv.(m).ELPD_per_trial_total;    % Post LV
    Y(6,mi) = psis_loo.PostTreat_Dun.(m).ELPD_per_trial_total;    % Post Dundee
    Y(7,mi) = psis_loo.HC.(m).ELPD_per_trial_total;               % HC
end

figure('Color','w','Name','PSIS-LOO (per trial)');
ax = axes; b = bar(Y,'grouped'); box off; grid on; hold on
for mi = 1:numel(model_order)
    b(mi).FaceColor = model_colors(mi,:);
    b(mi).EdgeColor = 'none';
end
set(ax,'XTick',1:numel(cats),'XTickLabel',cats,'XTickLabelRotation',20)
ylabel(ax,'PSIS-LOO ELPD (per trial)')
title(ax,'PSIS-LOO (per trial): all groups')
lg = legend(model_order,'Location','eastoutside','Box','off'); lg.Title.String = 'Models';

%% ===== WAIC (per trial) 
WAIC = model_comparisons.WAIC;

Y = zeros(numel(cats), numel(model_order));
for mi = 1:numel(model_order)
    m = model_order{mi};
    Y(1,mi) = WAIC.groups_original.(m).ELPD_WAIC_per_trial_total; % All Og
    Y(2,mi) = WAIC.groups_grouped.(m).ELPD_WAIC_per_trial_total;  % All Grouped
    Y(3,mi) = WAIC.PreTreat.(m).ELPD_WAIC_per_trial_total;        % Pre
    Y(4,mi) = WAIC.PostTreat.(m).ELPD_WAIC_per_trial_total;       % Post
    Y(5,mi) = WAIC.PostTreat_Liv.(m).ELPD_WAIC_per_trial_total;   % Post LV
    Y(6,mi) = WAIC.PostTreat_Dun.(m).ELPD_WAIC_per_trial_total;   % Post Dundee
    Y(7,mi) = WAIC.HC.(m).ELPD_WAIC_per_trial_total;              % HC
end

figure('Color','w','Name','WAIC (per trial)');
ax = axes; b = bar(Y,'grouped'); box off; grid on; hold on
for mi = 1:numel(model_order)
    b(mi).FaceColor = model_colors(mi,:);
    b(mi).EdgeColor = 'none';
end
set(ax,'XTick',1:numel(cats),'XTickLabel',cats,'XTickLabelRotation',20)
ylabel(ax,'WAIC ELPD (per trial)')
title(ax,'WAIC (per trial): all groups')
lg = legend(model_order,'Location','eastoutside','Box','off'); lg.Title.String = 'Models';

%% ===== MEAN (per trial) 
MEAN_LL = model_comparisons.MEAN_LL;
Y = zeros(numel(cats), numel(model_order));
for mi = 1:numel(model_order)
    m = model_order{mi};
    Y(1,mi) = MEAN_LL.groups_original.(m).LLmean_per_trial_total; % All Og
    Y(2,mi) = MEAN_LL.groups_grouped.(m).LLmean_per_trial_total;  % All Grouped
    Y(3,mi) = MEAN_LL.PreTreat.(m).LLmean_per_trial_total;        % Pre
    Y(4,mi) = MEAN_LL.PostTreat.(m).LLmean_per_trial_total;       % Post
    Y(5,mi) = MEAN_LL.PostTreat_Liv.(m).LLmean_per_trial_total;   % Post LV
    Y(6,mi) = MEAN_LL.PostTreat_Dun.(m).LLmean_per_trial_total;   % Post Dundee
    Y(7,mi) = MEAN_LL.HC.(m).LLmean_per_trial_total;              % HC
end

figure('Color','w','Name','Mean of LL (per trial)');
ax = axes; b = bar(Y,'grouped'); box off; grid on; hold on
for mi = 1:numel(model_order)
    b(mi).FaceColor = model_colors(mi,:);
    b(mi).EdgeColor = 'none';
end
set(ax,'XTick',1:numel(cats),'XTickLabel',cats,'XTickLabelRotation',20)
ylabel(ax,'LL (per trial)')
title(ax,'Mean (per trial): all groups')
lg = legend(model_order,'Location','eastoutside','Box','off'); lg.Title.String = 'Models';

%% ===== %Δ vs LOO — WAIC and MEAN_LL =====
% Inputs assumed present:
%   inferencedata, T_WAIC, T_PSIS
%   (T_* columns: Group, Model, A, B, AbsDiff, RelDiff_percent)

cats = {'All Og','All Grouped','PreTreat','PostTreat','PostTreat Liv','PostTreat Dun','HC'};

model_order = {'AlphaSM','AlphaSME','AlphaSMP','AlphaSMEP', ...
               'BayesSM','BayesSME','BayesSMP','BayesSMEP'};

alpha_cols = [0.98 0.82 0.82; 0.95 0.65 0.65; 0.90 0.48 0.48; 0.78 0.33 0.33];
bayes_cols = [0.82 0.88 0.98; 0.64 0.78 0.95; 0.47 0.65 0.90; 0.32 0.53 0.80];
model_colors = [alpha_cols; bayes_cols];

build_matrix = @(TT) ...
    cell2mat(arrayfun(@(gi) ...
        cell2mat(arrayfun(@(mi) ...
            TT.RelDiff_percent(strcmp(TT.Group, cats{gi}) & strcmp(TT.Model, model_order{mi})), ...
            (1:numel(model_order))', 'UniformOutput', false))', ...
        (1:numel(cats))', 'UniformOutput', false));

Y_WAIC = build_matrix(T_WAIC);
Y_PSIS = build_matrix(T_PSIS);

figure('Color','w','Name','%Δ vs LOO — WAIC');
ax1 = axes; hold(ax1,'on'); box off; grid on
b1 = bar(Y_WAIC,'grouped');
for mi = 1:numel(model_order)
    b1(mi).FaceColor = model_colors(mi,:);
    b1(mi).EdgeColor = 'none';
end
set(ax1,'XTick',1:numel(cats),'XTickLabel',cats,'XTickLabelRotation',20)
ylabel(ax1,'% difference vs LOO (per trial)')
title(ax1,'%Δ (MEAN-WAIC)')
lg1 = legend(model_order,'Location','eastoutside','Box','off'); lg1.Title.String = 'Models';

figure('Color','w','Name','%Δ vs LOO — MEAN_LL');
ax2 = axes; hold(ax2,'on'); box off; grid on
b2 = bar(Y_PSIS,'grouped');
for mi = 1:numel(model_order)
    b2(mi).FaceColor = model_colors(mi,:);
    b2(mi).EdgeColor = 'none';
end
set(ax2,'XTick',1:numel(cats),'XTickLabel',cats,'XTickLabelRotation',20)
ylabel(ax2,'% difference vs LOO (per trial)')
title(ax2,'%Δ (MEAN\_LL − LOO)')
lg2 = legend(model_order,'Location','eastoutside','Box','off'); lg2.Title.String = 'Models';
