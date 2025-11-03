function [loglikelihood, probability] = Model_fit_A(model, rewards, actions, alpha, beta, phi, persev)
% Model_fit_A — 4-bandit Rescorla–Wagner (SARSA) learner with softmax choice.
% Usage:
%   [loglikelihood, probability] = Model_fit_A(model, rewards, actions, alpha, beta, phi, persev)
%
% Inputs:
%   model   : 'AlphaSM' | 'AlphaSME' | 'AlphaSMP' | 'AlphaSMEP'
%   rewards : nT×4 rewards per trial and bandit
%   actions : nT×1 choices in 1–4 (0 = no response)
%   alpha   : learning rate
%   beta    : inverse temperature
%   phi     : exploration weight (default 0; via last-chosen bonus)
%   persev  : perseveration bonus (default 0)
%
% Outputs:
%   loglikelihood : sum log p(choice | model) over responded trials
%   probability   : nT×4 choice probabilities per trial
%
% Original author Will Gilmour 2023 DOI 10.1093/brain/awae025
% Adapted by Isla Barnard 2025 (oedema revision)
% Corresponding Author Tom Gilbertson  — https://github.com/tom-gilbertsons-lab

    arguments
        model
        rewards
        actions
        alpha
        beta
        phi = 0
        persev = 0
    end

    %% Set-up Alpha (RW/SARSA) models

    nT = length(actions);
    probability = zeros(nT, 4);          % Probability of choosing each bandit at given time
    value       = zeros(nT+1, 4);        % Predicted value of bandit
    value(1,:)  = [50, 50, 50, 50];      % Initial estimates (match Bayes models’ start)
    pred_error  = zeros(nT, 1);          % Prediction error per trial

    % Directed exploration bookkeeping: last chosen trial index per bandit
    LC  = zeros(1,4);                    % Last choice time (0 = never chosen yet)
    LCb = zeros(nT,4);                  % “Last-chosen back” (t - LC) per trial

    % Perseveration bonus (for SMP/SMEP)
    if strcmp(model,'AlphaSMP') || strcmp(model,'AlphaSMEP')
        pb = zeros(1,4); % perseveration bonus for models 
    end

    %% Models

    for t = 1:nT

        if actions(t) == 0
            value(t+1,:) = value(t,:);
            continue
        end

        LCb(t,:) = t - LC; % Update LCb for this time step (since each bandit was last chosen)


        if strcmp(model,'AlphaSMP') || strcmp(model,'AlphaSMEP')
            pb = zeros(1,4);
            if t > 1
                if actions(t-1) == actions(t)
                    pb(actions(t)) = persev;
                end
            end
        end
      
        switch model
            case 'AlphaSM'
                probability(t,:) = exp(beta .* value(t,:));                       % Standard SM

            case 'AlphaSME'
                probability(t,:) = exp(beta .* (value(t,:) + phi .* LCb(t,:)));   % SME rule

            case 'AlphaSMP'
                probability(t,:) = exp(beta .* (value(t,:) + pb));               % SMP rule

            case 'AlphaSMEP'
                probability(t,:) = exp(beta .* (value(t,:) + phi .* LCb(t,:) + pb)); % SMEP rule
        end

        % rest of learner 
        probability(t,:) = probability(t,:) ./ sum(probability(t,:));
        a = actions(t);
        R = rewards(t, a);
        pred_error(t)    = R - value(t, a);
        value(t+1,:)     = value(t,:);
        value(t+1, a)    = value(t, a) + alpha * pred_error(t);

        % Mark last chosen time
        LC(a) = t;

    end
    
    %% Log-likelihood over responded trials
    predicted_probability = zeros(nT,1);
    for n = 1:nT
        if actions(n) ~= 0
            predicted_probability(n) = probability(n, actions(n));
        end
    end
    predicted_probability = predicted_probability(predicted_probability ~= 0);
    loglikelihood = sum(log(predicted_probability + eps));
end
