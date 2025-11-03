%% Paramter Recovery: Draw Selection 

% For each GROUP × MODEL × SUBJECT, pick K=5 representative 
% posterior draws across params (beta, ±phi, ±persev) for recovery simulations.
%
% Method:
% 1) For each subject, take 10,000 per-draw log-likelihoods.
% 2) Sort (best→worst), keep central band 1001–9000 (drop both tails).
% 3) Select K evenly spaced draws within kept band
% 4) Save selected draw indices; get corresponding parameters & store.
% Isla Barnard 2025 (oedema revision)
% Corresponding Author Tom Gilbertson t.gilbertson@dundee.ac.uk
% https://github.com/tom-gilbertsons-lab

inferencedata = load("../Fitting/per_subject_draws.mat");
tmp = load('../ModelComparison/log_lik_all.mat');
log_likelihoods = tmp.log_likelihoods; clear tmp 
%%
K = 5;
sample_indices = round(linspace(1, 8000, K));

% I've left all of these in for [p

winning_models = {'AlphaSMP','AlphaSMEP','BayesSMP','BayesSMEP'};

posterior_param_draws_ranked = struct();

group_list= fieldnames(log_likelihoods);

for group_idx=1:numel(group_list)

    group = group_list{group_idx};
    nSubjects = size(log_likelihoods.(group).(winning_models{1}).loglikelihood, 2);
    
    for model_idx = 1:numel(winning_models)
        model = winning_models{model_idx};

        has_alpha = isfield(inferencedata.(group).(model),'alpha');
        has_phi = isfield(inferencedata.(group).(model),'phi');
        has_persev = isfield(inferencedata.(group).(model),'persev');

        beta   = zeros(nSubjects, K);
        if has_alpha,  alpha  = zeros(nSubjects, K); end
        if has_phi,    phi    = zeros(nSubjects, K); end
        if has_persev, persev = zeros(nSubjects, K); end

        log_lik = log_likelihoods.(group).(model).loglikelihood;   % [nDraws x nSubjects]
        [nDraws, ~] = size(log_lik);

        draw_indices = cell(1, nSubjects);

        for subject= 1:nSubjects 

            ll = log_lik(:,subject);
            [~, order_ll] = sort(ll, 'descend');
          
            hdi_draw_ids = order_ll(1001:9000); % central chunk of the log liks 

            selected_draw_ids = hdi_draw_ids(sample_indices);
            draw_indices{subject} = selected_draw_ids(:);

            beta_draws   = inferencedata.(group).(model).beta(subject,:).';
            if has_alpha,  alpha_draws  = inferencedata.(group).(model).alpha(subject,:).'; end
            if has_phi,    phi_draws    = inferencedata.(group).(model).phi(subject,:).';    end
            if has_persev, persev_draws = inferencedata.(group).(model).persev(subject,:).'; end

            beta(subject, :) = beta_draws(selected_draw_ids).';
            if has_alpha,  alpha(subject,:)   = alpha_draws(selected_draw_ids).'; end
            if has_phi,    phi(subject, :)    = phi_draws(selected_draw_ids).';    end
            if has_persev, persev(subject, :) = persev_draws(selected_draw_ids).'; end
           
        end    

        posterior_param_draws_ranked.(group).(model).draw_indices = draw_indices;
        posterior_param_draws_ranked.(group).(model).params.beta   = beta;
        if has_alpha,  posterior_param_draws_ranked.(group).(model).params.alpha    = alpha;  end 
        if has_phi,    posterior_param_draws_ranked.(group).(model).params.phi    = phi;    end
        if has_persev, posterior_param_draws_ranked.(group).(model).params.persev = persev; end

        posterior_param_draws_ranked.(group).(model).K = K;

    end
end

save('posterior_param_draws_ranked.mat','posterior_param_draws_ranked','-v7.3');

clearvars 