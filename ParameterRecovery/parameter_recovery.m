% Parameter Recovery 

tmp = load('posterior_param_draws_ranked.mat');
posterior_param_draws_ranked = tmp.posterior_param_draws_ranked;
clear tmp

param_recovery_fits= load('parameter_recovery_draws.mat');

%%
groups = fieldnames(param_recovery_fits);
% %models = {'BayesSMP','BayesSMEP'};
% %params_for_model = struct( ...
%     'BayesSMP',  {{'beta','persev'}}, ...
%     'BayesSMEP', {{'beta','phi','persev'}} );


models = {'BayesSMEP'};
params_for_model = struct('BayesSMEP', {{'beta','phi','persev'}} );
subject_key_fmt = 'subject_%02d';

param_recovery_summary_stats = struct();

for group_idx = 1:numel(groups)
    group = groups{group_idx};
    
    for model_idx = 1:numel(models)
        model = models{model_idx};
        param_list = params_for_model.(model);

        for param_idx = 1:numel(param_list)
            param = param_list{param_idx};

            posterior_draws = posterior_param_draws_ranked.(group).(model).params.(param);

            [nSubjects, K] = size(posterior_draws);
            recovered_means = zeros(K, nSubjects);
            recovered_hdis = zeros(2, K, nSubjects);


            for subject = 1:nSubjects

                sim_draws = param_recovery_fits.(group).(model).(sprintf(subject_key_fmt, subject)).(param);
                param_samples = reshape(sim_draws,K, []);

                recovered_means(:, subject) = mean(param_samples, 2);       
                recovered_hdis(1,:,subject) = prctile(param_samples, 2.5, 2)';
                recovered_hdis(2,:,subject) = prctile(param_samples, 97.5, 2)';

            end

           param_recovery_summary_stats.(group).(model).(param).posterior_draws = reshape(posterior_draws.', [], 1);
           param_recovery_summary_stats.(group).(model).(param).recovered_means = recovered_means(:);
           param_recovery_summary_stats.(group).(model).(param).recovered_hdis = reshape(recovered_hdis, 2, []); 



        end
    end
end


% 
% clear recovered_means recovered_hdis posterior_draws sim_draws param_samples
% clear subject_key_fmt nDraws nSubSims params_for_model groups models param_list 
% clear group model param subject nSubjects K param_idx model_idx group_idx


