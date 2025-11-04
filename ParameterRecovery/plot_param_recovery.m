%% Plot: Parameter recovery using param_recovery_summary_stats

group_labels = {'Pre Treat (n=37)','Post Treat Liverpool (n=12)','Post Treat Dundee (n = 25)', 'Healthy Controls'};
groups       = {'PreTreat','PostTreat_Liv','PostTreat_Dun','HC'};
models_recovered = {'BayesSMEP'};

params_recovered = struct( ...
    'BayesSMEP', {{'beta','phi','persev'}} );

subject_key_fmt = 'subject_%02d';

palette = struct( ...
    'PreTreat',      [0.901 0.623 0.000], ...  % orange
    'PostTreat_Liv', [0.835 0.369 0.000], ...  % red
    'PostTreat_Dun', [0.494 0.184 0.556], ...  % purple
    'HC',            [0.255 0.412 0.882]);     % blue

for model_idx = 1:numel(models_recovered)
    model = models_recovered{model_idx};
    param_list = params_recovered.(model);
    nParams = numel(param_list);

    fig = figure('Name', ['Parameter Recovery: ' model], 'Color','w');
    tl = tiledlayout(nParams, 5, 'TileSpacing','compact', 'Padding','compact');
    title(tl, ['Parameter recovery: ' model]);

    for param_idx = 1:nParams
        param_name = param_list{param_idx};

        % ---------- Column 1: ALL groups ----------
        ax_all = nexttile(tl, (param_idx-1)*5 + 1); hold(ax_all,'on');
        x_all = []; y_all = []; neg_all = []; pos_all = [];

        for group_idx = 1:numel(groups)
            group = groups{group_idx};

            x_grp_vec = param_recovery_summary_stats.(group).(model).(param_name).posterior_draws;   % [N x 1]
            y_grp_vec = param_recovery_summary_stats.(group).(model).(param_name).recovered_means;   % [N x 1]
            hdis      = param_recovery_summary_stats.(group).(model).(param_name).recovered_hdis;    % [2 x N]
            lo_vec    = hdis(1, :).';
            hi_vec    = hdis(2, :).';

            neg_grp_vec = y_grp_vec - lo_vec;
            pos_grp_vec = hi_vec - y_grp_vec;

            errorbar(ax_all, x_grp_vec, y_grp_vec, neg_grp_vec, pos_grp_vec, 'o', ...
                'Color', palette.(group), 'MarkerFaceColor', palette.(group), ...
                'MarkerSize', 3, 'LineStyle','none', 'CapSize', 0);

            x_all   = [x_all;   x_grp_vec];
            y_all   = [y_all;   y_grp_vec];
            neg_all = [neg_all; neg_grp_vec];
            pos_all = [pos_all; pos_grp_vec];
        end

        xymin_all = min([x_all; y_all]);
        xymax_all = max([x_all; y_all]);
        plot(ax_all, [xymin_all xymax_all], [xymin_all xymax_all], '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 1);
        [r_all, p_all] = corr(x_all, y_all, 'type','Pearson', 'rows','complete');
        p_txt = sprintf('p = %.3g', p_all); if p_all < 0.001, p_txt = 'p < 0.001'; end
        text(ax_all, 0.05, 0.92, sprintf('r = %.2f, %s', r_all, p_txt), ...
            'Units','normalized', 'FontSize', 9, 'FontWeight','bold', 'Color', [0.15 0.15 0.15]);
        title(ax_all, 'All groups');
        xlabel(ax_all, [param_name ' (posterior draw)']);
        ylabel(ax_all, [param_name ' (recovered mean \pm 95% CI)']);
        xlim(ax_all, [xymin_all xymax_all]); ylim(ax_all, [xymin_all xymax_all]);
        box(ax_all,'on'); grid(ax_all,'on');
        legend(ax_all, group_labels, 'Location','bestoutside');

        % ---------- Columns 2–5: per group ----------
        for group_idx = 1:numel(groups)
            group = groups{group_idx};
            ax = nexttile(tl, (param_idx-1)*5 + 1 + group_idx); hold(ax,'on');

            x_grp_vec = param_recovery_summary_stats.(group).(model).(param_name).posterior_draws;   % [N x 1]
            y_grp_vec = param_recovery_summary_stats.(group).(model).(param_name).recovered_means;   % [N x 1]
            hdis      = param_recovery_summary_stats.(group).(model).(param_name).recovered_hdis;    % [2 x N]
            lo_vec    = hdis(1, :).';
            hi_vec    = hdis(2, :).';

            neg_grp_vec = y_grp_vec - lo_vec;
            pos_grp_vec = hi_vec - y_grp_vec;

            errorbar(ax, x_grp_vec, y_grp_vec, neg_grp_vec, pos_grp_vec, 'o', ...
                'Color', palette.(group), 'MarkerFaceColor', palette.(group), ...
                'MarkerSize', 3, 'LineStyle','none', 'CapSize', 0);

            xymin = min([x_grp_vec; y_grp_vec]); 
            xymax = max([x_grp_vec; y_grp_vec]);
            plot(ax, [xymin xymax], [xymin xymax], '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 1);
            [r_grp, p_grp] = corr(x_grp_vec, y_grp_vec, 'type','Pearson', 'rows','complete');
            p_txt = sprintf('p = %.3g', p_grp); if p_grp < 0.001, p_txt = 'p < 0.001'; end
            text(ax, 0.05, 0.92, sprintf('r = %.2f, %s', r_grp, p_txt), ...
                'Units','normalized', 'FontSize', 9, 'FontWeight','bold', 'Color', [0.15 0.15 0.15]);

            title(ax, group_labels{group_idx});
            xlabel(ax, [param_name ' (posterior draw)']);
            ylabel(ax, [param_name ' (recovered mean \pm 95% CI)']);
            xlim(ax, [xymin xymax]); ylim(ax, [xymin xymax]);
            box(ax,'on'); grid(ax,'on');
        end
    end
end
