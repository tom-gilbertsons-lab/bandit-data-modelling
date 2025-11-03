% included for completeness, all chatGPT generated; not used for
% publication just checking as we go
load('model_comparisons.mat','model_comparisons');
%% ===== LPT (per trial)
BIC=model_comparisons.BIC;
model_order = {'AlphaSM','AlphaSME','AlphaSMP','AlphaSMEP', ...
               'BayesSM','BayesSME','BayesSMP','BayesSMEP'};

alpha_cols = [0.98 0.82 0.82; 0.95 0.65 0.65; 0.90 0.48 0.48; 0.78 0.33 0.33];
bayes_cols = [0.82 0.88 0.98; 0.64 0.78 0.95; 0.47 0.65 0.90; 0.32 0.53 0.80];
model_colors = [alpha_cols; bayes_cols];

% Categories for each subplot
cats1 = {'All','PreTreat','PostTreat','HC'};
cats2 = {'All','PreTreat','PostTreat Liv','PostTreat Dun','HC'};

% Data matrices: rows = categories, cols = models
Y1 = zeros(numel(cats1), numel(model_order));
for mi = 1:numel(model_order)
    m = model_order{mi};
    Y1(1,mi) = BIC.groups_original.(m).LPT_total;
    Y1(2,mi) = BIC.PreTreat.(m).LPT_total;
    Y1(3,mi) = BIC.PostTreat.(m).LPT_total;
    Y1(4,mi) = BIC.HC.(m).LPT_total;
end

Y2 = zeros(numel(cats2), numel(model_order));
for mi = 1:numel(model_order)
    m = model_order{mi};
    Y2(1,mi) = BIC.groups_grouped.(m).LPT_total;
    Y2(2,mi) = BIC.PreTreat.(m).LPT_total;
    Y2(3,mi) = BIC.PostTreat_Liv.(m).LPT_total;
    Y2(4,mi) = BIC.PostTreat_Dun.(m).LPT_total;
    Y2(5,mi) = BIC.HC.(m).LPT_total;
end

% ---- Plot ----
figure('Color','w','Name','Likelihood Per Trial');
t = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

% Left: original groups
ax1 = nexttile;
b1 = bar(Y1,'grouped'); box off; grid on; hold on
for mi = 1:numel(model_order)
    b1(mi).FaceColor = model_colors(mi,:);
    b1(mi).EdgeColor = 'none';
end
set(ax1,'XTick',1:numel(cats1),'XTickLabel',cats1,'XTickLabelRotation',20)
ylabel(ax1,'LPT (per trial)')

title(ax1,'Likelihood Per Trial: original groups')

% Right: Liv/Dun split
ax2 = nexttile;
b2 = bar(Y2,'grouped'); box off; grid on; hold on
for mi = 1:numel(model_order)
    b2(mi).FaceColor = model_colors(mi,:);
    b2(mi).EdgeColor = 'none';
end
set(ax2,'XTick',1:numel(cats2),'XTickLabel',cats2,'XTickLabelRotation',20)
ylabel(ax2,'LPT (per trial)')

title(ax2,'Likelihood Per Trial: post op split')

% Legend once (on the right)
lg = legend(ax2, model_order,'Location','eastoutside','Box','off');
lg.Title.String = 'Models';

%% ===== PSIS-LOO (per trial) 
psis_loo = model_comparisons.psis_loo;
model_order = {'AlphaSM','AlphaSME','AlphaSMP','AlphaSMEP', ...
               'BayesSM','BayesSME','BayesSMP','BayesSMEP'};

alpha_cols = [0.98 0.82 0.82; 0.95 0.65 0.65; 0.90 0.48 0.48; 0.78 0.33 0.33];
bayes_cols = [0.82 0.88 0.98; 0.64 0.78 0.95; 0.47 0.65 0.90; 0.32 0.53 0.80];
model_colors = [alpha_cols; bayes_cols];

% Categories for each subplot
cats1 = {'All','PreTreat','PostTreat','HC'};
cats2 = {'All','PreTreat','PostTreat Liv','PostTreat Dun','HC'};

% Data matrices: rows = categories, cols = models
Y1 = zeros(numel(cats1), numel(model_order));
for mi = 1:numel(model_order)
    m = model_order{mi};
    Y1(1,mi) = psis_loo.groups_original.(m).ELPD_per_trial_total;
    Y1(2,mi) = psis_loo.PreTreat.(m).ELPD_per_trial_total;
    Y1(3,mi) = psis_loo.PostTreat.(m).ELPD_per_trial_total;
    Y1(4,mi) = psis_loo.HC.(m).ELPD_per_trial_total;
end

Y2 = zeros(numel(cats2), numel(model_order));
for mi = 1:numel(model_order)
    m = model_order{mi};
    Y2(1,mi) = psis_loo.groups_grouped.(m).ELPD_per_trial_total;
    Y2(2,mi) = psis_loo.PreTreat.(m).ELPD_per_trial_total;
    Y2(3,mi) = psis_loo.PostTreat_Liv.(m).ELPD_per_trial_total;
    Y2(4,mi) = psis_loo.PostTreat_Dun.(m).ELPD_per_trial_total;
    Y2(5,mi) = psis_loo.HC.(m).ELPD_per_trial_total;
end

% ---- Plot ----
figure('Color','w','Name','PSIS-LOO (per trial)');
t = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

% Left: original groups
ax1 = nexttile;
b1 = bar(Y1,'grouped'); box off; grid on; hold on
for mi = 1:numel(model_order)
    b1(mi).FaceColor = model_colors(mi,:);
    b1(mi).EdgeColor = 'none';
end
set(ax1,'XTick',1:numel(cats1),'XTickLabel',cats1,'XTickLabelRotation',20)
ylabel(ax1,'ELPD (per trial)')
title(ax1,'PSIS-LOO (per trial): original groups')

% Right: Liv/Dun split
ax2 = nexttile;
b2 = bar(Y2,'grouped'); box off; grid on; hold on
for mi = 1:numel(model_order)
    b2(mi).FaceColor = model_colors(mi,:);
    b2(mi).EdgeColor = 'none';
end
set(ax2,'XTick',1:numel(cats2),'XTickLabel',cats2,'XTickLabelRotation',20)
ylabel(ax2,'ELPD (per trial)')
title(ax2,'PSIS-LOO (per trial): post op split')

% Legend once (on the right)
lg = legend(ax2, model_order,'Location','eastoutside','Box','off');
lg.Title.String = 'Models';

%% ===== WAIC (per trial) 
WAIC = model_comparisons.WAIC;
model_order = {'AlphaSM','AlphaSME','AlphaSMP','AlphaSMEP', ...
               'BayesSM','BayesSME','BayesSMP','BayesSMEP'};

alpha_cols = [0.98 0.82 0.82; 0.95 0.65 0.65; 0.90 0.48 0.48; 0.78 0.33 0.33];
bayes_cols = [0.82 0.88 0.98; 0.64 0.78 0.95; 0.47 0.65 0.90; 0.32 0.53 0.80];
model_colors = [alpha_cols; bayes_cols];

% Categories for each subplot
cats1 = {'All','PreTreat','PostTreat','HC'};
cats2 = {'All','PreTreat','PostTreat Liv','PostTreat Dun','HC'};

% ----- Data matrices: rows = categories, cols = models
Y1 = zeros(numel(cats1), numel(model_order));
for mi = 1:numel(model_order)
    m = model_order{mi};
    % ORIGINAL groups (includes combined PostTreat)
    Y1(1,mi) = WAIC.groups_original.(m).ELPD_WAIC_per_trial_total; % All (original)
    Y1(2,mi) = WAIC.PreTreat.(m).ELPD_WAIC_per_trial_total;
    Y1(3,mi) = WAIC.PostTreat.(m).ELPD_WAIC_per_trial_total;       % combined PostTreat
    Y1(4,mi) = WAIC.HC.(m).ELPD_WAIC_per_trial_total;
end

Y2 = zeros(numel(cats2), numel(model_order));
for mi = 1:numel(model_order)
    m = model_order{mi};
    % GROUPED split (uses Liv/Dun only, NOT combined PostTreat)
    Y2(1,mi) = WAIC.groups_grouped.(m).ELPD_WAIC_per_trial_total;  % All (grouped)
    Y2(2,mi) = WAIC.PreTreat.(m).ELPD_WAIC_per_trial_total;
    Y2(3,mi) = WAIC.PostTreat_Liv.(m).ELPD_WAIC_per_trial_total;   % split
    Y2(4,mi) = WAIC.PostTreat_Dun.(m).ELPD_WAIC_per_trial_total;   % split
    Y2(5,mi) = WAIC.HC.(m).ELPD_WAIC_per_trial_total;
end

% ----- Plot
figure('Color','w','Name','WAIC (per trial)');
t = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

% Left: original groups
ax1 = nexttile;
b1 = bar(Y1,'grouped'); box off; grid on; hold on
for mi = 1:numel(model_order)
    b1(mi).FaceColor = model_colors(mi,:);
    b1(mi).EdgeColor = 'none';
end
set(ax1,'XTick',1:numel(cats1),'XTickLabel',cats1,'XTickLabelRotation',20)
ylabel(ax1,'ELPD_{WAIC} (per trial)')
title(ax1,'WAIC (per trial): original groups')

% Right: Liv/Dun split (no combined PostTreat)
ax2 = nexttile;
b2 = bar(Y2,'grouped'); box off; grid on; hold on
for mi = 1:numel(model_order)
    b2(mi).FaceColor = model_colors(mi,:);
    b2(mi).EdgeColor = 'none';
end
set(ax2,'XTick',1:numel(cats2),'XTickLabel',cats2,'XTickLabelRotation',20)
ylabel(ax2,'ELPD_{WAIC} (per trial)')
title(ax2,'WAIC (per trial): post site split')

% Legend once (on the right)
lg = legend(ax2, model_order,'Location','eastoutside','Box','off');
lg.Title.String = 'Models';


%% ===== MEAN (per trial) 
MEAN_LL = model_comparisons.MEAN_LL;
model_order = {'AlphaSM','AlphaSME','AlphaSMP','AlphaSMEP', ...
               'BayesSM','BayesSME','BayesSMP','BayesSMEP'};

alpha_cols = [0.98 0.82 0.82; 0.95 0.65 0.65; 0.90 0.48 0.48; 0.78 0.33 0.33];
bayes_cols = [0.82 0.88 0.98; 0.64 0.78 0.95; 0.47 0.65 0.90; 0.32 0.53 0.80];
model_colors = [alpha_cols; bayes_cols];

% Categories for each subplot
cats1 = {'All','PreTreat','PostTreat','HC'};
cats2 = {'All','PreTreat','PostTreat Liv','PostTreat Dun','HC'};

% ----- Data matrices: rows = categories, cols = models
Y1 = zeros(numel(cats1), numel(model_order));
for mi = 1:numel(model_order)
    m = model_order{mi};
    % ORIGINAL groups (includes combined PostTreat)
    Y1(1,mi) = MEAN_LL.groups_original.(m).LLmean_per_trial_total; % All (original)
    Y1(2,mi) = MEAN_LL.PreTreat.(m).LLmean_per_trial_total;
    Y1(3,mi) = MEAN_LL.PostTreat.(m).LLmean_per_trial_total;       % combined PostTreat
    Y1(4,mi) = MEAN_LL.HC.(m).LLmean_per_trial_total;
end

Y2 = zeros(numel(cats2), numel(model_order));
for mi = 1:numel(model_order)
    m = model_order{mi};
    % GROUPED split (uses Liv/Dun only, NOT combined PostTreat)
    Y2(1,mi) = MEAN_LL.groups_original.(m).LLmean_per_trial_total;   % All (grouped)
    Y2(2,mi) = MEAN_LL.PreTreat.(m).LLmean_per_trial_total;
    Y2(3,mi) = MEAN_LL.PostTreat_Liv.(m).LLmean_per_trial_total;    % split
    Y2(4,mi) = MEAN_LL.PostTreat_Dun.(m).LLmean_per_trial_total;   % split
    Y2(5,mi) = MEAN_LL.HC.(m).LLmean_per_trial_total;
end

% ----- Plot
figure('Color','w','Name','WAIC (per trial)');
t = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

% Left: original groups
ax1 = nexttile;
b1 = bar(Y1,'grouped'); box off; grid on; hold on
for mi = 1:numel(model_order)
    b1(mi).FaceColor = model_colors(mi,:);
    b1(mi).EdgeColor = 'none';
end
set(ax1,'XTick',1:numel(cats1),'XTickLabel',cats1,'XTickLabelRotation',20)
ylabel(ax1,'ELPD_{WAIC} (per trial)')
title(ax1,'WAIC (per trial): original groups')

% Right: Liv/Dun split (no combined PostTreat)
ax2 = nexttile;
b2 = bar(Y2,'grouped'); box off; grid on; hold on
for mi = 1:numel(model_order)
    b2(mi).FaceColor = model_colors(mi,:);
    b2(mi).EdgeColor = 'none';
end
set(ax2,'XTick',1:numel(cats2),'XTickLabel',cats2,'XTickLabelRotation',20)
ylabel(ax2,'ELPD_{WAIC} (per trial)')
title(ax2,'WAIC (per trial): post site split')

% Legend once (on the right)
lg = legend(ax2, model_order,'Location','eastoutside','Box','off');
lg.Title.String = 'Models';

%% ===== %Δ vs LOO — WAIC and MEAN_LL =====
% Inputs assumed present:
%   inferencedata, T_WAIC, T_PSIS
%   (T_* columns: Group, Model, A, B, AbsDiff, RelDiff_percent)

% Natural groups from your data:
cats = fieldnames(inferencedata);   % row order

% Consistent model order + colours
model_order = {'AlphaSM','AlphaSME','AlphaSMP','AlphaSMEP', ...
               'BayesSM','BayesSME','BayesSMP','BayesSMEP'};

alpha_cols = [0.98 0.82 0.82; 0.95 0.65 0.65; 0.90 0.48 0.48; 0.78 0.33 0.33];
bayes_cols = [0.82 0.88 0.98; 0.64 0.78 0.95; 0.47 0.65 0.90; 0.32 0.53 0.80];
model_colors = [alpha_cols; bayes_cols];

% Helper to build matrix (rows=groups in 'cats', cols=model_order) from a T table
build_matrix = @(TT) ...
    cell2mat(arrayfun(@(gi) ...
        cell2mat(arrayfun(@(mi) ...
            TT.RelDiff_percent(strcmp(TT.Group, cats{gi}) & strcmp(TT.Model, model_order{mi})), ...
            (1:numel(model_order))', 'UniformOutput', false))', ...
        (1:numel(cats))', 'UniformOutput', false));

% Matrices of % differences
Y_WAIC = build_matrix(T_WAIC);   % (WAIC − LOO)/|LOO| * 100
Y_PSIS = build_matrix(T_PSIS);   % (MEAN_LL − LOO)/|LOO| * 100

% -------- Plot: WAIC vs LOO --------
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

% -------- Plot: MEAN\_LL vs LOO --------
figure('Color','w','Name','%Δ vs LOO — MEAN\_LL');
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
