%% CHOICE CLASSIFICATION 
% BAYESIAN LEARNER ONLY FOR Oct 29th 2025, only looking in depth into the
% Kalman Filter models 
% Original author Will Gilmour 2023 DOI 10.1093/brain/awae025
% Adapted by Isla Barnard 2025 (oedema revision)
% Corresponding Author Tom Gilbertson t.gilbertson@dundee.ac.uk
% https://github.com/tom-gilbertsons-lab


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


%%
choice_classifications = struct();

group_list = fieldnames(behavioural_data);

for group_idx = 1:numel(group_list)

    group = group_list{group_idx};
    all_behavioural = behavioural_data.(group);
    nSubjects = numel(all_behavioural);

    choice_ratios = zeros(nSubjects,3);
    choice_classified   = cell(nSubjects,1);

    for subject = 1:nSubjects

        local_behavioural = all_behavioural(subject);
        walk    = local_behavioural.Walk;
        actions = local_behavioural.Actions;
        rewards = squeeze(payoffs(walk,:,:));

        [choices_categorised, choice_type] = Choice_Classification_B(rewards, actions);

        choice_ratios(subject,:) = choices_categorised;
        choice_classified{subject}     = choice_type;
    end

    choice_classifications.(group).choice_ratios = choice_ratios;
    choice_classifications.(group).choice_class  = choice_classified;
end

save('choice_classifications.mat','choice_classifications','-v7.3');

function [choice_class, choice_type] = Choice_Classification_B(rewards, actions)

    nT = length(actions);

    value = zeros(nT+1,4);
    value(1,:) = [50,50,50,50];

    var = zeros(nT+1,4);
    var(1,:) = [4,4,4,4];

    decay = 0.9836; decay_center = 50;
    var_O = 4.0;    var_D = 2.8;

    for t = 1:nT
        if actions(t)==0
            value(t+1,:) = value(t,:);
            var(t+1,:)   = var(t,:);
        else
            R = rewards(t,actions(t));
            pred_error = R - value(t,actions(t));
            K = (var(t,actions(t)).^2) ./ ( (var(t,actions(t)).^2) + (var_O.^2) );

            value(t+1,:) = value(t,:);
            value(t+1,actions(t)) = value(t,actions(t)) + K*pred_error;

            var(t+1,:) = var(t,:);
            var(t+1,actions(t)) = sqrt( (1-K) .* (var(t,actions(t)).^2) );

            value(t+1,:) = decay * value(t+1,:) + (1 - decay) * decay_center;
            var(t+1,:)   = sqrt( (decay.^2) .* (var(t+1,:).^2) + (var_D.^2) );
        end
    end

    %% Choice Categorisation 

    exploit_choices          = cell(nT,1);
    directed_explore_choices = cell(nT,1);
    random_explore_choices   = cell(nT,1);
    choice_type              = zeros(nT,1);

    for n = 2:nT
        % exploit arm(s)
        exploit = find(value(n,:) == max(value(n,:)));
        % candidates for directed exploration
        explore = find(value(n,:) ~= max(value(n,:)));
        % pick the highest‐var among those
        directed_explore = explore(var(n,explore) == max(var(n,explore)));
        
        if length(directed_explore) > 1
            random_explore_choices{n}   = directed_explore;
            directed_explore_choices{n} = [];
        else
            directed_explore_choices{n} = directed_explore;
            random_explore_choices{n}   = setdiff(1:4, [exploit, directed_explore]);
        end
        
        exploit_choices{n} = exploit;

        % label the actual choice
        a = actions(n);
        if a ~= 0
            if     ismember(a, exploit_choices{n})
                choice_type(n) = 1;
            elseif ismember(a, directed_explore_choices{n})
                choice_type(n) = 2;
            elseif ismember(a, random_explore_choices{n})
                choice_type(n) = 3;
            end
        end
    end

    first_resp = find(actions~=0,1,'first');
    if ~isempty(first_resp)
        choice_type(first_resp) = 3;
    end

    % compute proportions over real choices
    choice_class = [ sum(choice_type==1),sum(choice_type==2),sum(choice_type==3) ] ./ nnz(actions);
end
