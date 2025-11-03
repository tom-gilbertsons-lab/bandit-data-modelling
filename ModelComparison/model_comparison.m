%%
% Model Comparison for Oedema revision 
% comparing models via psis-loo leave one outs
% also computing loo for parameter recovery 
% Isla Barnard October 2025ish 
%% NOTES
% BAYESIAN LEARNER ONLY FOR Oct 15th 2025; added RW/SARSAs Oct 24th 2025
% for revision of Oedema paper.
% (must add subdir PSIS-LOO to path; recommend you run 1-2 to check dependencies 
% 29th Oct : 
% Using other information criterion for model comparison; 
% PSIS-LOO k vals are almost all > 1 (psis-loo is loo/CV which would be 'nice to have' but 
% isn't actually what we're asking of the models. 

%%
% preamble and data loading 
walks = load('stimuli-gaussian');
payoffs = zeros(3,300,4);

payoffs(1,:,:) = walks.payoffs1(1:300,:);
payoffs(2,:,:) = walks.payoffs2(1:300,:);
payoffs(3,:,:) = walks.payoffs3(1:300,:);

clear walks 
%% Raw behavioural data (for the walk & actions from  given participant)

tmp = load('../behavioural_data/Control_Thal/Full_data_set_Control_Thal.mat');
hc = tmp.Data;
tmp = load('../behavioural_data/Pre_Thal/Full_data_set_Pre_Thal.mat');
prethal = tmp.Data;
tmp = load('../behavioural_data/Post_Thal/Full_data_set_Post_Thal.mat');
postthal = tmp.Data;

% building into hc, pre,post & post_lv, dd (using same names as stan export

behavioural_data = struct();
liverpool_post_subjects = [4,7,9,11,12,13,15,19,24,27,29,31];
dundee_post_subjects   = [1,2,3,5,6,8,10,14,16,17,18,20,21,22,23,25,26,28,30,32,33,34,35,36,37];

%HC
behavioural_data.HC = repmat(struct('Walk',[],'Actions',[]), 1, numel(hc));
for s = 1:numel(hc)
    behavioural_data.HC(s).Walk    = hc{1,s}.Walk;
    behavioural_data.HC(s).Actions = hc{1,s}.Actions(:);
end

% PreTreat
behavioural_data.PreTreat = repmat(struct('Walk',[],'Actions',[]), 1, numel(prethal));
for s = 1:numel(prethal)
    behavioural_data.PreTreat(s).Walk    = prethal{1,s}.Walk;
    behavioural_data.PreTreat(s).Actions = prethal{1,s}.Actions(:);
end

% PostTreat
behavioural_data.PostTreat = repmat(struct('Walk',[],'Actions',[]), 1, numel(postthal));
for s = 1:numel(postthal)
    behavioural_data.PostTreat(s).Walk    = postthal{1,s}.Walk;
    behavioural_data.PostTreat(s).Actions = postthal{1,s}.Actions(:);
end

% PostTreat_Liv
behavioural_data.PostTreat_Liv = repmat(struct('Walk',[],'Actions',[]), 1, numel(liverpool_post_subjects));
for i = 1:numel(liverpool_post_subjects)
    s = liverpool_post_subjects(i);
    behavioural_data.PostTreat_Liv(i).Walk    = postthal{1,s}.Walk;
    behavioural_data.PostTreat_Liv(i).Actions = postthal{1,s}.Actions(:);
end
%# PostTreat_Dun
behavioural_data.PostTreat_Dun = repmat(struct('Walk',[],'Actions',[]), 1, numel(dundee_post_subjects));
for i = 1:numel(dundee_post_subjects)
    s = dundee_post_subjects(i);
    behavioural_data.PostTreat_Dun(i).Walk    = postthal{1,s}.Walk;
    behavioural_data.PostTreat_Dun(i).Actions = postthal{1,s}.Actions(:);
end

clear tmp hc prethal postthal s i dundee_post_subjects liverpool_post_subjects

%% Load Fits (fitted in cmdPyStan)
% cmdPyStan fits as structs (see python)
inferencedata = load("../Fitting/per_subject_draws.mat");
% % check model names are as expected 
% group_list = fieldnames(inferencedata);
% group = group_list{1};
% model_list = fieldnames(inferencedata.(group));
% disp(model_list)
%%
% par pool : optional 
if isempty(gcp('nocreate'))
    parpool('local')
end

%% loglik from each 4x2500 fits as returned from stan 
% we ignore broadcast var warning (per-worker instances crashed matlab)
% (HP z2 i9 ~300 seconds on 8 workers) 

tic
nDraws = 10000;
group_list = fieldnames(inferencedata);
log_likelihoods= struct();

for group_idx=1:numel(group_list)
 
    group = group_list{group_idx};
    nSubjects = numel(behavioural_data.(group));
    model_list = fieldnames(inferencedata.(group));
    
    for model_idx = 1:numel(model_list)

        model = model_list{model_idx};
        all_behavioural = behavioural_data.(group);
        log_lik = zeros(nDraws, nSubjects);

        parfor subject=1:nSubjects 
    
            fprintf('STARTING Subject %d | Group %d | Model %d\n', subject, group_idx, model_idx);
            
            local_behavioural = all_behavioural(subject);
            local_payoffs = payoffs;
            walk = local_behavioural.Walk;
            actions = local_behavioural.Actions;
            rewards = squeeze(local_payoffs(walk, :,:));

            if contains(model,'Alpha')
                alpha_draws  = inferencedata.(group).(model).alpha(subject,:).';
                beta_draws   = inferencedata.(group).(model).beta(subject,:).';
                phi_draws    = zeros(nDraws,1);
                persev_draws = zeros(nDraws,1);
                if isfield(inferencedata.(group).(model),['phi' ...
                        ''])
                    phi_draws    = inferencedata.(group).(model).phi(subject,:).';    
                end
                if isfield(inferencedata.(group).(model),'persev')
                    persev_draws = inferencedata.(group).(model).persev(subject,:).'; 
                end
    
                for draw = 1:nDraws
                    [ll, ~] = Model_fit_A(model, rewards, actions, alpha_draws(draw), beta_draws(draw), phi_draws(draw), persev_draws(draw));
                    log_lik(draw, subject) = ll;
                end

            elseif contains(model,'Bayes')
    
                beta_draws   = inferencedata.(group).(model).beta(subject,:).';
                phi_draws    = zeros(nDraws,1);
                persev_draws = zeros(nDraws,1);
                if isfield(inferencedata.(group).(model),'phi')
                    phi_draws    = inferencedata.(group).(model).phi(subject,:).';    
                end
                if isfield(inferencedata.(group).(model),'persev')
                    persev_draws = inferencedata.(group).(model).persev(subject,:).'; 
                end
    
                for draw = 1:nDraws
                    [ll, ~] = Model_fit_B(model, rewards, actions, beta_draws(draw), phi_draws(draw), persev_draws(draw));
                    log_lik(draw, subject) = ll;
                end

            end

            fprintf('FINISHING Subject %d | Group %d | Model %d\n', subject, group_idx, model_idx);
        end
      
        log_likelihoods.(group).(model).loglikelihood = log_lik;

    end
end
toc

save('log_lik_all.mat','log_likelihoods','-v7.3');
clear rewards actions nDraws alpha_draws beta_draws phi_draws persev_draws draw subject nSubjects
clear group group_list group_idx model model_list model_idx
clear all_behavioural log_lik 




%% MODEL COMPARISON METRICS 

% log_likelihoods = load('log_lik_all.mat');
model_comparisons = struct(); % master struct for publication 

% as discussed in readme, our aim here is model comparison- which model best 
% describes the observed data; rather than out of sample prediction? 
% I'm not not convinced as to what psis-loo gives us over the mean liklihood 
% in our dataset given it's not a defined distribution of likelihoods over
% all subjects. 

% for completeness; metrics summed over both post-treat groupings
% 
original_groups = {'HC','PreTreat','PostTreat'};
grouped_groups =  {'HC','PreTreat','PostTreat_Liv','PostTreat_Dun'};

valid_trials = struct();
group_list = fieldnames(log_likelihoods);

for group_idx=1:numel(group_list)
    group = group_list{group_idx};
    nSubjects = numel(behavioural_data.(group));

    valid_trials.(group) = zeros(nSubjects,1);
    for subject = 1:nSubjects
        valid_trials.(group)(subject,1) = nnz(behavioural_data.(group)(subject).Actions);
    end
end

model_comparisons.valid_trials = valid_trials;
save('model_comparisons.mat','model_comparisons','-v7.3');
clear subject nSubjects
%% BIC & LPT 
% Bayes Information Criterion & Liklihood per trial (using bayesian
% evidence)
% as suggested by (the authoritative) 'Ten Simple Rules.... Wilson & Collins' https://doi.org/10.7554/eLife.49547

BIC = struct();
group_list = fieldnames(log_likelihoods);

for group_idx=1:numel(group_list)
    group = group_list{group_idx};

    model_list = fieldnames(log_likelihoods.(group));

    for model_idx = 1:numel(model_list)
        model = model_list{model_idx};
       
        L = log_likelihoods.(group).(model).loglikelihood;  % log-likelihoods over a given fit 
        LLmax = max(L, [], 1)';

        n_K = 0;
        if isfield(inferencedata.(group).(model),'alpha'),  n_K = n_K + 1; end
        if isfield(inferencedata.(group).(model),'beta'),   n_K = n_K + 1; end
        if isfield(inferencedata.(group).(model),'phi'),    n_K = n_K + 1; end
        if isfield(inferencedata.(group).(model),'persev'), n_K = n_K + 1; end

        valid_trials_per_subject= valid_trials.(group);

        bic_subject = -2*LLmax + n_K*log(valid_trials_per_subject);
        bic_total = sum(bic_subject);

        % LPT from BIC: LPT ≈ exp( -BIC / (2*T) )
        LPT_subject = exp(-bic_subject ./ (2 .* valid_trials_per_subject));
        LPT_overall = exp(-bic_total / (2 * sum(valid_trials_per_subject)));

        BIC.(group).(model).BIC           = bic_subject;
        BIC.(group).(model).BIC_total     = bic_total;
        BIC.(group).(model).LPT          = LPT_subject;
        BIC.(group).(model).LPT_total    = LPT_overall;
 
    end
end

% totals 
model_list = fieldnames(BIC.(original_groups{1}));

for model_idx = 1:numel(model_list)
    model = model_list{model_idx};

    total_bic= 0; total_trials = 0;
    for group_idx = 1:numel(original_groups)
        group = original_groups{group_idx};
        total_bic    = total_bic    + BIC.(group).(model).BIC_total;
        total_trials = total_trials + sum(valid_trials.(group));
    end
    BIC.groups_original.(model).BIC_total      = total_bic;
    BIC.groups_original.(model).valid_trials   = total_trials;
    BIC.groups_original.(model).LPT_total      = exp(-total_bic / (2 * total_trials));  % per-trial LPT over pooled data

    total_bic= 0; total_trials = 0;
    for group_idx = 1:numel(grouped_groups)
        group = grouped_groups{group_idx};
        total_bic    = total_bic    + BIC.(group).(model).BIC_total;
        total_trials = total_trials + sum(valid_trials.(group));
    end
    BIC.groups_grouped.(model).BIC_total      = total_bic;
    BIC.groups_grouped.(model).valid_trials   = total_trials;
    BIC.groups_grouped.(model).LPT_total      = exp(-total_bic / (2 * total_trials));  % per-trial LPT over pooled data
    
end

model_comparisons.BIC = BIC;

save('model_comparisons.mat','model_comparisons','-v7.3');
clear group group_list group_idx model model_list model_idx valid_trials_per_subject 
clear bic_subject bic_total LPT_subject LPT_overall 
clear L LL LLmax total_bic total_trials n_K
%% PSIS-LOO 
% on running this, almost all k vals are >1, some >2. 
% (the model isn't predicitive of an unseen subject) 

psis_loo = struct();
group_list = fieldnames(log_likelihoods);

for group_idx = 1:numel(group_list)
    group = group_list{group_idx};
    model_list = fieldnames(log_likelihoods.(group));
    valid_trials_per_subject = valid_trials.(group);

    for model_idx = 1:numel(model_list)
        model = model_list{model_idx};
        log_lik = log_likelihoods.(group).(model).loglikelihood;

        % PSIS-LOO
        [elpd_total, elpd_subject, k_subject] = psisloo(log_lik);

        elpd_per_trial_subject = elpd_subject ./ valid_trials_per_subject;
        elpd_per_trial_total   = elpd_total / sum(valid_trials_per_subject);

        % store
        psis_loo.(group).(model).ELPD                     = elpd_subject;
        psis_loo.(group).(model).ELPD_total               = elpd_total;
        psis_loo.(group).(model).ELPD_per_trial           = elpd_per_trial_subject;
        psis_loo.(group).(model).ELPD_per_trial_total     = elpd_per_trial_total;
        psis_loo.(group).(model).k                        = k_subject;
    end
end

% totals
model_list = fieldnames(psis_loo.(original_groups{1}));

for model_idx = 1:numel(model_list)
    model = model_list{model_idx};

    total_elpd = 0; total_trials = 0;
    for group_idx = 1:numel(original_groups)
        group = original_groups{group_idx};
        total_elpd  = total_elpd  + psis_loo.(group).(model).ELPD_total;
        total_trials = total_trials + sum(valid_trials.(group));
    end
    psis_loo.groups_original.(model).ELPD_total             = total_elpd;
    psis_loo.groups_original.(model).valid_trials           = total_trials;
    psis_loo.groups_original.(model).ELPD_per_trial_total   = total_elpd / total_trials;

    total_elpd = 0; total_trials = 0;
    for group_idx = 1:numel(grouped_groups)
        group = grouped_groups{group_idx};
        total_elpd  = total_elpd  + psis_loo.(group).(model).ELPD_total;
        total_trials = total_trials + sum(valid_trials.(group));
    end
    psis_loo.groups_grouped.(model).ELPD_total             = total_elpd;
    psis_loo.groups_grouped.(model).valid_trials           = total_trials;
    psis_loo.groups_grouped.(model).ELPD_per_trial_total   = total_elpd / total_trials;
end

model_comparisons.psis_loo = psis_loo;

save('model_comparisons.mat','model_comparisons','-v7.3');

clear group group_list group_idx model model_list model_idx valid_trials_per_subject 
clear log_lik elpd_total elpd_subject elpd_per_trial_subject elpd_per_trial_total
clear total_trials total_elpd k_subject 

%% WAIC 
% Computes per-unit ELPD_WAIC, totals, and per-trial normalisations.

WAIC = struct();
group_list = fieldnames(log_likelihoods);

for group_idx = 1:numel(group_list)
    group = group_list{group_idx};
    model_list = fieldnames(log_likelihoods.(group));
    valid_trials_per_subject = valid_trials.(group);

    for model_idx = 1:numel(model_list)
        model = model_list{model_idx};

        % log_lik: draws x units (units = subjects or plays)
        log_lik = log_likelihoods.(group).(model).loglikelihood;
        nSubjects  = size(log_lik, 2);

        % lppd and p_waic per unit
        lppd_subject  = zeros(nSubjects,1);
        pwaic_subject = zeros(nSubjects,1);

        for subject = 1:nSubjects
            ell = log_lik(:,subject);
            a = max(ell);                             % stability
            lppd_subject(subject)  = a + log(mean(exp(ell - a)));
            pwaic_subject(subject) = var(ell, 0, 1);        % across draws
        end

        elpd_waic_subject = lppd_subject - pwaic_subject;
        elpd_waic_total   = sum(elpd_waic_subject);
        waic_total        = -2 * elpd_waic_total;

        % per-trial normalisation (matches PSIS-LOO normalisation)
        elpd_waic_per_trial_subject = elpd_waic_subject ./ valid_trials_per_subject;
        elpd_waic_per_trial_total   = elpd_waic_total / sum(valid_trials_per_subject);

        WAIC.(group).(model).ELPD_WAIC                   = elpd_waic_subject;
        WAIC.(group).(model).ELPD_WAIC_total             = elpd_waic_total;
        WAIC.(group).(model).ELPD_WAIC_per_trial         = elpd_waic_per_trial_subject;
        WAIC.(group).(model).ELPD_WAIC_per_trial_total   = elpd_waic_per_trial_total;
        WAIC.(group).(model).WAIC_total                  = waic_total;
    end
end

% totals
model_list = fieldnames(WAIC.(original_groups{1}));

for model_idx = 1:numel(model_list)
    model = model_list{model_idx};

    total_elpd = 0; total_trials = 0;
    for group_idx = 1:numel(original_groups)
        group = original_groups{group_idx};
        total_elpd  = total_elpd  + WAIC.(group).(model).ELPD_WAIC_total;
        total_trials = total_trials + sum(valid_trials.(group));
    end
    WAIC.groups_original.(model).ELPD_WAIC_total             = total_elpd;
    WAIC.groups_original.(model).valid_trials               = total_trials;
    WAIC.groups_original.(model).ELPD_WAIC_per_trial_total  = total_elpd / total_trials;
    WAIC.groups_original.(model).WAIC_total                 = -2 * total_elpd;

    total_elpd = 0; total_trials = 0;
    for group_idx = 1:numel(grouped_groups)
        group = grouped_groups{group_idx};
        total_elpd  = total_elpd  + WAIC.(group).(model).ELPD_WAIC_total;
        total_trials = total_trials + sum(valid_trials.(group));
    end
    WAIC.groups_grouped.(model).ELPD_WAIC_total             = total_elpd;
    WAIC.groups_grouped.(model).valid_trials               = total_trials;
    WAIC.groups_grouped.(model).ELPD_WAIC_per_trial_total  = total_elpd / total_trials;
    WAIC.groups_grouped.(model).WAIC_total                 = -2 * total_elpd;
end

model_comparisons.WAIC = WAIC;

save('model_comparisons.mat','model_comparisons','-v7.3');

clear group group_list group_idx model model_list model_idx valid_trials_per_subject 
clear nSubjects subject total_elpd log_lik total_trials
clear ell a lppd_subject pwaic_subject elpd_waic_subject elpd_waic_total waic_total
clear elpd_waic_per_trial_total elpd_waic_per_trial_subject 
%% %% MEAN_LL mean log-likelihood over draws
% Literal mean log-likelihood across posterior draws per unit (subject/play),
% plus totals and per-trial normalisation

MEAN_LL = struct();

group_list = fieldnames(log_likelihoods);

for group_idx = 1:numel(group_list)
    group = group_list{group_idx};
    model_list = fieldnames(log_likelihoods.(group));
    valid_trials_per_subject = valid_trials.(group);

    for model_idx = 1:numel(model_list)
        model = model_list{model_idx};

        % log_lik: 
        log_lik = log_likelihoods.(group).(model).loglikelihood;

        % mean across draws for each unit
        ll_mean_subject = mean(log_lik, 1)';   
        ll_mean_total   = sum(ll_mean_subject);

        % per-trial normalisation
        ll_mean_per_trial_subject = ll_mean_subject ./ valid_trials_per_subject;
        ll_mean_per_trial_total   = ll_mean_total / sum(valid_trials_per_subject);

        MEAN_LL.(group).(model).LLmean                   = ll_mean_subject;
        MEAN_LL.(group).(model).LLmean_total             = ll_mean_total;
        MEAN_LL.(group).(model).LLmean_per_trial         = ll_mean_per_trial_subject;
        MEAN_LL.(group).(model).LLmean_per_trial_total   = ll_mean_per_trial_total;
    end
end

% totals 
model_list = fieldnames(MEAN_LL.(original_groups{1}));

for model_idx = 1:numel(model_list)
    model = model_list{model_idx};

    total_ll = 0; total_trials = 0;
    for group_idx = 1:numel(original_groups)
        group = original_groups{group_idx};
        total_ll     = total_ll     + MEAN_LL.(group).(model).LLmean_total;
        total_trials = total_trials + sum(valid_trials.(group));
    end
    MEAN_LL.groups_original.(model).LLmean_total           = total_ll;
    MEAN_LL.groups_original.(model).valid_trials           = total_trials;
    MEAN_LL.groups_original.(model).LLmean_per_trial_total = total_ll / total_trials;

    total_ll = 0; total_trials = 0;
    for group_idx = 1:numel(grouped_groups)
        group = grouped_groups{group_idx};
        total_ll     = total_ll     + MEAN_LL.(group).(model).LLmean_total;
        total_trials = total_trials + sum(valid_trials.(group));
    end
    MEAN_LL.groups_grouped.(model).LLmean_total           = total_ll;
    MEAN_LL.groups_grouped.(model).valid_trials           = total_trials;
    MEAN_LL.groups_grouped.(model).LLmean_per_trial_total = total_ll / total_trials;
end

model_comparisons.MEAN_LL = MEAN_LL;

save('model_comparisons.mat','model_comparisons','-v7.3');

clear group group_list group_idx model model_list model_idx valid_trials_per_subject 
clear nSubjects subject total_elpd log_lik total_trials
clear ll_mean_subject ll_mean_total ll_mean_per_trial_subject ll_mean_per_trial_total
clear total_ll 
   
%%
%% Comparison of model metrics; WAIC vs PSIS-LOO vs MEAN 
%%

T_PSIS = compare_metrics(MEAN_LL, 'LLmean_per_trial_total', ...
                          psis_loo,     'ELPD_per_trial_total');

T_WAIC = compare_metrics(MEAN_LL, 'LLmean_per_trial_total', ...
                           WAIC, 'ELPD_WAIC_per_trial_total');


%%
%% Categorise PSIS-LOO K values 
%% Per-group Pareto-k category counts ("pie-style") -> cat_k
% Uses existing group_list and psis_loo.

%% Per-group Pareto-k category counts ("pie-style") -> cat_k_table
% Uses your existing naming: group_list, group_idx, group_name, model_names, model_idx.

group_list = fieldnames(log_likelihoods);                % cell array of group names
number_of_groups = numel(group_list);

counts_lt_0p7   = zeros(number_of_groups,1);
counts_0p7_to_1 = zeros(number_of_groups,1);
counts_ge_1     = zeros(number_of_groups,1);

for group_idx = 1:number_of_groups
    group_name   = group_list{group_idx};
    model_names  = fieldnames(psis_loo.(group_name));

    all_k_values_for_group = [];
    for model_idx = 1:numel(model_names)
        model_name = model_names{model_idx};
        all_k_values_for_group = [all_k_values_for_group; psis_loo.(group_name).(model_name).k(:)]; %#ok<AGROW>
    end

    counts_lt_0p7(group_idx)   = sum(all_k_values_for_group < 0.7);
    counts_0p7_to_1(group_idx) = sum(all_k_values_for_group >= 0.7 & all_k_values_for_group < 1.0);
    counts_ge_1(group_idx)     = sum(all_k_values_for_group >= 1.0);
end

cat_k_table = table( ...
    string(group_list(:)), ...
    counts_lt_0p7, counts_0p7_to_1, counts_ge_1, ...
    'VariableNames', {'Group','k < p7','0.7< k < 1','k > 1'});

disp(cat_k_table)

clear group_idx group_name model_idx model_name model_names number_of_groups all_k_values_for_group


%% Param Means (don't thik we've used this; but left it in) 
original_param_means = compute_parameter_means(original_priors);
new_param_means = compute_parameter_means(new_priors);

function parameter_means = compute_parameter_means(inferenceData)
% returns per-subject means for each param in inferenceData

    group_list = fieldnames(inferenceData);
    for group_idx = 1:numel(group_list)
        group = group_list{group_idx};
        model_list = fieldnames(inferenceData.(group));
        for model_idx = 1:numel(model_list)
            model = model_list{model_idx};
            param_list = fieldnames(inferenceData.(group).(model));
            for param_idx = 1:numel(param_list)
                param  = param_list{param_idx};
                DRAWS  = inferenceData.(group).(model).(param);   % subjects x draws
                mu     = mean(DRAWS, 2);                          % subjects x 1
                means.(group).(model).(param) = mu;
            end
        end
    end
    parameter_means = means;
end

function T = compare_metrics(structA, fieldA, structB, fieldB)
%% Compare per-trial totals between two metric structs
% Inputs:
%   structA : first metrics struct   (e.g., psis_loo)
%   fieldA  : per-trial total field  (e.g., 'ELPD_per_trial_total')
%   structB : second metrics struct  (e.g., WAIC)
%   fieldB  : per-trial total field  (e.g., 'ELPD_WAIC_per_trial_total')
%
% Output:
%   T       : table with Group, Model, A, B, AbsDiff, RelDiff_percent
%
% Notes:
% - Groups are taken as the intersection of top-level fields (excluding
%   'groups_original' and 'groups_grouped').
% - Models are taken from the first group shared by both structs.
% - Relative difference is (B - A) / |A| in percent.

all_groups_A = fieldnames(structA);
all_groups_B = fieldnames(structB);

group_list = intersect( ...
    setdiff(all_groups_A, {'groups_original','groups_grouped'}), ...
    setdiff(all_groups_B, {'groups_original','groups_grouped'}) );

% models from the first real group present in both
g0 = group_list{1};
models_A = fieldnames(structA.(g0));
models_B = fieldnames(structB.(g0));
model_list = intersect(models_A, models_B);

nG = numel(group_list);
nM = numel(model_list);

A_vals   = zeros(nG, nM);
B_vals   = zeros(nG, nM);
AbsDiff  = zeros(nG, nM);
RelDiff  = zeros(nG, nM);

for gi = 1:nG
    g = group_list{gi};
    for mi = 1:nM
        m = model_list{mi};

        a_val = structA.(g).(m).(fieldA);
        b_val = structB.(g).(m).(fieldB);

        A_vals(gi,mi) = a_val;
        B_vals(gi,mi) = b_val;

        d = b_val - a_val;
        AbsDiff(gi,mi) = d;
        RelDiff(gi,mi) = 100 * d / abs(a_val);
    end
end

% long-form table
rows = nG * nM;
Group  = strings(rows,1);
Model  = strings(rows,1);
Acol   = zeros(rows,1);
Bcol   = zeros(rows,1);
Dcol   = zeros(rows,1);
Pcol   = zeros(rows,1);

k = 1;
for gi = 1:nG
    for mi = 1:nM
        Group(k) = group_list{gi};
        Model(k) = model_list{mi};
        Acol(k)  = A_vals(gi,mi);
        Bcol(k)  = B_vals(gi,mi);
        Dcol(k)  = AbsDiff(gi,mi);
        Pcol(k)  = RelDiff(gi,mi);
        k = k + 1;
    end
end

T = table(Group, Model, ...
          round(Acol,4), round(Bcol,4), ...
          round(Dcol,5), round(Pcol,2), ...
          'VariableNames', {'Group','Model','A','B','AbsDiff','RelDiff_percent'});
end


%% Little WriteOut CSV Helpers 
function T = writeout_csv(metric_struct, value_field, filename, use_original)
%% Write model metric to CSV (3 s.f.) for grouped groups by default.
% If use_original is true, writes the original groups instead.
%
% Inputs:
%   metric_struct : e.g., model_comparisons.psis_loo  or  model_comparisons.BIC
%   value_field   : e.g., 'ELPD_per_trial_total'      or  'LPT_total'
%   filename      : output CSV filename
%   use_original  : optional flag; true -> original groups, false/omit -> grouped
%
% Returns:
%   T : MATLAB table written to CSV

if ~exist('use_original','var'), use_original = false; end

if use_original
    row_labels = {'All','PreTreat','PostTreat','HC'};
    model_list = fieldnames(metric_struct.groups_original);
    Y = zeros(numel(row_labels), numel(model_list));
    for mi = 1:numel(model_list)
        m = model_list{mi};
        Y(1,mi) = metric_struct.groups_original.(m).(value_field);
        Y(2,mi) = metric_struct.PreTreat.(m).(value_field);
        Y(3,mi) = metric_struct.PostTreat.(m).(value_field);
        Y(4,mi) = metric_struct.HC.(m).(value_field);
    end
else
    row_labels = {'All','PreTreat','PostTreat_Liv','PostTreat_Dun','HC'};
    model_list = fieldnames(metric_struct.groups_grouped);
    Y = zeros(numel(row_labels), numel(model_list));
    for mi = 1:numel(model_list)
        m = model_list{mi};
        Y(1,mi) = metric_struct.groups_grouped.(m).(value_field);
        Y(2,mi) = metric_struct.PreTreat.(m).(value_field);
        Y(3,mi) = metric_struct.PostTreat_Liv.(m).(value_field);
        Y(4,mi) = metric_struct.PostTreat_Dun.(m).(value_field);
        Y(5,mi) = metric_struct.HC.(m).(value_field);
    end
end

Y = round(Y, 3, 'significant');
T = array2table(Y, 'VariableNames', model_list, 'RowNames', row_labels);
writetable(T, filename, 'WriteRowNames', true);
end
