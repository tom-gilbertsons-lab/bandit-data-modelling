function [loglikelihood,probability]=Model_fit_B(model, rewards, actions,beta, phi, persev)

% Model_fit_B — 4-bandit Bayesian learner with softmax choice.
% Usage:
%   [loglikelihood, probability] = Model_fit_B(model, rewards, actions, beta, phi, persev)
%
% Inputs:
%   model   : 'BayesSM' | 'BayesSME' | 'BayesSMP' | 'BayesSMEP'
%   rewards : nT×4 rewards per trial and bandit
%   actions : nT×1 choices in 1–4 (0 = no response)
%   beta    : inverse temperature
%   phi     : exploration weight (default 0)
%   persev  : perseveration bonus (default 0)
%
% Outputs:
%   loglikelihood : sum log p(choice | model) over responded trials
%   probability   : nT×4 choice probabilities per trial
%
%
% Original author Will Gilmour 2023 DOI 10.1093/brain/awae025
% Adapted by Isla Barnard 2025 (oedema revision)
% Corresponding Author Tom Gilbertson t.gilbertson@dundee.ac.uk
% https://github.com/tom-gilbertsons-lab
    
        arguments
            model
            rewards
            actions
            beta
            phi = 0
            persev = 0
        end
    
    %% Set-up Bayesian Learner models
    
    nT = length(actions);
    probability = zeros(nT,4); % Probability of choosing each bandit at given time
    value = zeros(nT+1,4); % Predicted value of bandit (mu)
    value(1,:)=[50,50,50,50]; % initial bandit estimates
    var = zeros(nT+1,4); % predicted variance of bandit
    var(1,:) = [4,4,4,4];% prior belief of variance
    
    decay = 0.9836; decay_center  = 50; % decay params 
    var_O = 4.0; var_D = 2.8; % diffusion variances
    
    % Perseveration bonus (for SMP/SMEP)
    if strcmp(model,'BayesSMP')||strcmp(model, 'BayesSMEP')
        pb = zeros(1,4); % perseveration bonus for models 
    end
    pred_error = zeros(nT,1); % noting the prediction error for each action
    
    %% Models
    
    for t = 1:nT  % if no response, carry over from last made response 

        if actions(t)==0
            value(t+1,:) =value(t,:);
            var(t+1,:)=var(t,:);

        else
            switch model

                case 'BayesSM'
        
                    probability(t,:) = exp(beta.*value(t,:)); % Standard SM rule
        
                case 'BayesSME'
    
                    probability(t,:) = exp(beta.*(value(t,:)+phi*var(t,:))); % SME rule
    
                case 'BayesSMP'
    
                    probability(t,:) = exp(beta.*(value(t,:)+pb)); % SMP rule
    
                case 'BayesSMEP'
    
                    probability(t,:) = exp(beta.*(value(t,:)+pb+(phi*var(t,:)))); % SMEP rule
            end
            % rest of learner 
            probability(t,:) = probability(t,:)./sum(probability(t,:));
            R = rewards(t,actions(t));
            pred_error(t) = R-value(t,actions(t));
            K = (var(t,actions(t)).^2 ./ (var(t,actions(t)).^2 + var_O.^2) ); % calculate Kalman gain
            value(t+1,:) =value(t,:);
            value(t+1,actions(t)) = value(t,actions(t)) + K*pred_error(t); % update predictions
            var(t+1,:) =var(t,:);
            var(t+1,actions(t)) = sqrt((1-K).*(var(t,actions(t)).^2)); 
          
            % Decay
            value(t+1,:)= (decay * value(t+1,:) + (1-decay) * decay_center);
            var(t+1,:) = sqrt( decay.^2 * var(t+1,:).^2 + var_D.^2 );
            
            if strcmp(model,'BayesSMP')||strcmp(model, 'BayesSMEP')
                pb = zeros(1,4);
                if t > 1
                    if  (actions(t-1)==actions(t))
                        pb(actions(t))  = persev;
                    end
                end
            end
        end
    
    end
    
    %% loglikelihood 

    predicted_probability = zeros(nT, 1);

    for n = 1:nT
        if actions(n)~=0
            predicted_probability(n) = probability(n,actions(n));
        end
    end

    predicted_probability = predicted_probability(predicted_probability~=0);
    loglikelihood = sum(log(predicted_probability + eps));
end