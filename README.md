
## Review of Behavioural Modeling for Thalamotomy Oedema (July & Oct 2025) 
#### Behavioural data modelling (splitting postop by site) 

We use MATLAB and python. `cmdPyStan` is used for modelling (wrapped in `.ipynb` notebooks, using `joblib` for parallelisation) and have used Arviz for initial checks (however MATLAB is standard in field so structs <--> dicts throughout). 

No datasets in the github repo.
See OSF for data & code.

#### General Notes 

Code is written for [Mackenzie, Gilmour,... Gilbertson, Focused ultrasound neuromodulation of mediodorsal thalamus disrupts decision flexibility during reward learning](https://www.biorxiv.org/content/10.1101/2025.06.03.657634v1) (preprint, currently in revision) based on pipelines developed for [Gilmour, Mackenzie,.... Gilbertson, Impaired value-based decision-making in Parkinson’s disease apathy](https://doi.org/10.1093/brain/awae025). 

IB: Isla Barnard\
WG: Will Gilmour\
**Corresponding author** TG: Tom Gilbertson
t.gilbertson@dundee.ac.uk\
https://github.com/tom-gilbertsons-lab


Directories with key datasets highlighted ** . Datasets (with exception of bandit gaussian walks) will not be in the github repo; find them on OSF 
```
.
├── README.md
├── ccn.yaml
├── behavioural_data/...
│   ├── Control_Thal
│   ├── Post_Thal
│   ├── Pre_Thal
│   └── **stimuli-gaussian.mat**
├── ChoiceAnalysis/
│   ├── choice_classification.m
│   └── **choice_classifications.mat**
├── Fitting/
│   ├── analysis.ipynb
│   ├── Fits/...
│   ├── fitting.ipynb
│   └── **per_subject_draws.mat**
├── ModelComparison/
│   ├── **log_lik_all.mat**
│   ├── model_comparison.m
│   ├── model_comparisons.mat
│   ├── Model_fit_A.m
│   ├── Model_fit_B.m
│   └── PSIS-LOO/...
├── oedema_Oct25.code-workspace
├── ParameterRecovery/
│   ├── fits/...
│   ├── **parameter_recovery_draws.mat**
│   ├── parameter_recovery_fitting_BAYES.ipynb
│   ├── parameter_recovery.m
│   ├── parameter_recovery_simulation_BAYES.ipynb
│   ├── paramter_recovery_formatting.ipynb
│   ├── posterior_param_draw_ranks.m
│   ├── **posterior_param_draws_ranked.mat**
│   └── simulated_data
└── Stan
    ├── stan_models/
    │   ├── AlphaSME_model.stan
    │   ├── AlphaSMEP_model.stan
    │   ├── AlphaSM_model.stan
    │   ├── AlphaSMP_model.stan
    │   ├── BayesSME_model.stan
    │   ├── BayesSMEP_model.stan
    │   ├── BayesSM_model.stan
    │   └── BayesSMP_model.stan
    ├── stan_parameter_recovery/...
    └── stan_simulations/...
```

Have provided ([IB's](https://github.com/i-brnrd)) conda env used for computational modelling of behavioural data as `ccn.yaml`.\
Recreate with `conda env create -n ccn -f ccn.yaml` and use via `conda activate ccn`.

Datasets (dicts & structs) usually go [GROUP] × [MODEL] × [SUBJECT].


**NB**
Oedema paper submitted June 2025. When IB was modelling preliminary data for different project (July 2025) spotted typos in [priors within Stan models](https://discourse.mc-stan.org/t/hierarchical-model-behavioural-data-should-param-standard-deviation-priors-be-group-level-or-inside-per-subject-loop/40148/2). This coincided with the receipt of the oedema paper review, where it was decided to split the postop data by site; so IB wrote this repo based on TG & WG's work [Gilmour et.al.](https://doi.org/10.1093/brain/awae025).

 
### Models  `./Stan/...`

All models are originally written by WG [Gilmour et.al.](https://doi.org/10.1093/brain/awae025).\
**No changes** to the models or decision rules. 
However stan code has been updated from pyStan to cmdPyStan (eg. array syntax) and priors/ hyperparameters have been updated (IB, 2025). 

### Fitting `./Fitting/...`

`./Fitting/fitting.ipynb` reformats the behavioural data from concatenated .csv format, then compiles & fits Stan models (see `Stan/stan-models`):

### Model Families and Free Parameters

| Model        | Description                                | Free Parameters                  |
|---------------|---------------------------------------------|----------------------------------|
| **AlphaSM**   | Delta-rule learning                        | α (learning rate), β (inverse temperature) |
| AlphaSME      | + Exploration term                         | α, β, φ (exploration)            |
| AlphaSMP      | + Perseveration term                       | α, β, ρ (perseveration)          |
| AlphaSMEP     | + Exploration & Perseveration              | α, β, φ, ρ                       |
| **BayesSM**   | Kalman Filter learning                     | β (inverse temperature)          |
| BayesSME      | + Exploration term                         | β, φ (exploration)               |
| BayesSMP      | + Perseveration term                       | β, ρ (perseveration)             |
| BayesSMEP     | + Exploration & Perseveration              | β, φ, ρ                          |


All using 
```
CHAINS= 4 nWarmup = 2500 nSamples = 2500
```

*There are occasional divergent transitions in the fits, more commonly in the delta rule models, contact authors for details (addressing these was out of scope in this refit).*\
`cmdPyStan` fits are written out as `.csv`  into `fits/[group]/[model]/[model_name]-YYYYMMDDHHMMSS_CHAIN.csv` so e.g. `AlphaSME_model-20251009150541_4.csv` is the 4th chain of one run in early October 2025. 

`./Fitting/analysis.ipynb` loads fits and converts to [Arviz](https://python.arviz.org/en/stable/) inference data objects for look at posteriors. Parameters of interest are written out to MATLAB as `per_subject_draws.mat`. (NB: If fits are aborted mid-run (or more than one fit is run without redirecting output), there may be extra .csv files in `fits/[group]/[model]/...` that should be removed before running our postprocessing code). 


## Model comparison  `./ModelComparison/...`

See `model_comparison.m` script. 

Suggest using the parfor for significant speedup to calculate the log-likelihood (suppress/ignore broadcast var warnings and keep an eye on RAM). Builds `log_lik_all.mat` for metrics calculated in the rest of `model_comparison.m` and stored in `model_comparisons.mat`. There are plotting scripts (chatGPT generated) within `plot_logliks.m`. 

### Bayes Information Criterion and Liklihood Per Trial 

After running though PSIS-LOO for model comparison, we found the pareto k-values were as follows (see [here](https://mc-stan.org/loo/reference/pareto-k-diagnostic.html) for more). In the table below each entry is reported as 

$$
N_{k < 0.7}/N_{0.7 < k < 1.0}/ N_{ k > 1.0}  
$$



       Group           AlphaSM         AlphaSME         AlphaSMP       AlphaSMEP  
    _______________    ____________    _____________    ____________    ____________

    "HC"               "2 / 26 / 4"    "2 / 17 / 13"    "0 / 0 / 32"    "0 / 0 / 32"
    "PreTreat"         "0 / 28 / 9"    "1 / 23 / 13"    "0 / 0 / 37"    "0 / 0 / 37"
    "PostTreat"        "2 / 28 / 7"    "1 / 20 / 16"    "0 / 0 / 37"    "0 / 0 / 37"
    "PostTreat_Liv"    "2 / 9 / 1"     "1 / 3 / 8"      "0 / 0 / 12"    "0 / 0 / 12"
    "PostTreat_Dun"    "2 / 15 / 8"    "0 / 17 / 8"     "0 / 0 / 25"    "0 / 0 / 25"

         Group           BayesSM         BayesSME         BayesSMP       BayesSMEP  
    _______________    ____________    _____________    ____________    ____________

    "HC"               "1 / 24 / 7"    "4 / 21 / 7"     "0 / 0 / 32"    "0 / 0 / 32"
    "PreTreat"         "0 / 34 / 3"    "3 / 26 / 8"     "0 / 0 / 37"    "0 / 0 / 37"
    "PostTreat"        "1 / 29 / 7"    "1 / 26 / 10"    "0 / 0 / 37"    "0 / 0 / 37"
    "PostTreat_Liv"    "1 / 6 / 5"     "0 / 6 / 6"      "0 / 0 / 12"    "0 / 0 / 12"
    "PostTreat_Dun"    "0 / 19 / 6"    "2 / 13 / 10"    "0 / 0 / 25"    "0 / 0 / 25"


Clearly almost all pareto k-values < 0.7.\
PSIS-LOO asks how well each model predicts unseen data, without penalising for additional parameters.
For example, in this dataset, though post-op patients have different parameters, on average, than healthy controls, a post-op patient's behavioural data would never be predictable from the others (and so, as expected, pareto k-values are generally > 0.7). Also PSIS-LOO (& WAIC), both CV approximations, are very close to the mean of the likelihoods- see `model_comparisons.mat`).

Is LOO-CV or LOO-CV approximation needed to answer which proposed cognitive algorithm best describes the data? (we don't have time to run LOO-CV).

As per Wilson & Collins 2019, have included the BIC (Bayes Information Criterion) and the LPT (Liklihood per trial) as suggested by the authoritative 'Ten Simple Rules....' https://doi.org/10.7554/eLife.49547 

**Bayes Information Criterion (BIC)** (Appendix 2, Wilson & Collins 2019)

$$
\textrm{BIC} = -2 \ln\hat{\mathscr{L}} + k\ln T
$$

Where $\hat{\mathscr{L}}$ is the value of the log likelihood at the maximum likelihood estimate of the parameters $\hat{\theta}^{MLE}_m$, and $k$ the number of free paramters (penalised). 

The Bayesian Evidence 

$$ 
E_m= \log \int d\theta_m p(d_{1:T}| \theta_m,m)p(\theta_m|m)
$$ 

is such that 

$$
\textrm{BIC} \approx -2 E_m
$$

And the likelihood-per-trial,

$$
LPT = \exp{\frac{E_m}{T}}
$$

Represents the average probability with which the model predicts each choice. 


## Model Metrics `./ChoiceAnalysis/...`

To complete with TG's codes for e.g. P(stay) & P(choose best bandit). 

**Choice Classification**

The script `choice_classification.m` uses the Kalman Filter representation of value to classify behavioural choices into Exploitative, Directed Explorative or Random Explorative. 
As before, originally written by WG [Gilmour et.al.](https://doi.org/10.1093/brain/awae025) and was adapted for this refit. 

## Parameter Recovery `./ParameterRecovery/...`

Parameter recovery was run on the winning model is BayesSMEP (by all metrics examined in `model_comparison.m`) 

**Posterior Sampling**

We sampled the posterior to test parameter recovery across typical (not exceptional) posterior fits (rather than the means of posterior params). 
The script `posterior_param_draw_ranks.m` selects K=5 posterior draws. For each subject, the 10000 draws are ranked by log likelihood value, top & bottom 10% are excluded (retaining draws ranked 1001:9000). From this bulk of the posterior mass, 5 evenly spaced draws are used to sample parameter values which are stored in `posterior_param_draws_ranked.mat`. 

**Behavioural Data Simulation**

The notebook `parameter_recovery_simulation.ipynb` loads in behavioural data to obtain each participants walks. Per participant, 3 repeats of each of the K=5 samples are simulated using stan (`./Stan/stan_simulations/...`) (a total of 15 per participant). The simulated datasets are stored in `./simulated_data/YYYY-MM-DD-HH-MM-SS-simulations` as `simulations_stan_struct.mat` (and also the stan generated .csvs are retained). There is a matplotlib plotting function at the end of the notebook if needed. 

**Simulated Behavioural Data Fitting**

As before, we do parallelised stan fits in `parameter_recovery_fitting.ipynb`. We used empirical Bayes (not hierarchical) with priors taken from the distributions of the grand means of the posteriors, over all groups (see  (`./Stan/stan_parameter_recovery/...`). 

*Though not included in the published analysis, parameter recovery was performed for some delta rule models. Recovery was poor (especially alpha, which just regressed to the prior). We understand this can be better recovered by setting the initial value to [0,0,0,0], but refitting was out of scope as the delta rules were not the winning models).*

Here, fits are in `fits/[group]/[model]/[subject]/[model_name]-YYYYMMDDHHMMSS_CHAIN.csv`. Again if fits are aborted mid run, there may be extra .csvs in `fits/[group]/[model]/[subject]/...` that should be removed beofre post processing. `parameter_recovery_formatting.ipynb` formats the .csv stan fits for MATLAB, and parameters stored in  `parameter_recovery_draws.mat`. 

**Parameter Recovery Analysis**

`simulations_stan_struct.mat` and `parameter_recovery_draws.mat` are loaded into MATLAB using `parametter_recovery.m` which calculates the means and the HDI for each simulated parameter, storing this in `param_recovery_summary_stats.mat`. There is a plotting file (ChatGPT generated) to check these in `plot_param_recovery.m`, 


