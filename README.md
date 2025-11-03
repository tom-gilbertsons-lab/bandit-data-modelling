
## Review of Behavioural Modeling for Thalamotomy Oedema (July & Oct 2025) 
#### Behavioural data modelling (splitting postop by site) 

We use MATLAB and python. `cmdPyStan` is used for modelling (wrapped in `.ipynb` notebooks, using `joblib` for parallelisation) and have used Arviz for initial checks (however MATLAB is standard in field so structs <--> dicts throughout). 

The github repo won't have data in it (see the .gitignore); the OSF version does (over at XXXX). 


#### General Notes 

IB: Isla Barnard\
WG: Will Gilmour\
**Corresponding author** TG: Tom Gilbertson
t.gilbertson@dundee.ac.uk\
https://github.com/tom-gilbertsons-lab


Directories with key datasets etc. highlighted 
```
.
├── README.md
├── ccn.yaml
├── behavioural_data/...
│   ├── Control_Thal
│   ├── Post_Thal
│   ├── Pre_Thal
│   └── stimuli-gaussian.mat
├── ChoiceAnalysis/
│   ├── choice_classification.m
│   └── choice_classifications.mat
├── Fitting/
│   ├── analysis.ipynb
│   ├── Fits/...
│   ├── fitting.ipynb
│   └── per_subject_draws.mat
├── ModelComparison/
│   ├── log_lik_all.mat
│   ├── model_comparison.m
│   ├── model_comparisons.mat
│   ├── Model_fit_A.m
│   ├── Model_fit_B.m
│   └── PSIS-LOO/...
├── oedema_Oct25.code-workspace
├── ParameterRecovery/
│   ├── fits/...
│   ├── parameter_recovery_draws.mat
│   ├── parameter_recovery_fitting_BAYES.ipynb
│   ├── parameter_recovery.m
│   ├── parameter_recovery_simulation_BAYES.ipynb
│   ├── paramter_recovery_formatting.ipynb
│   ├── posterior_param_draw_ranks.m
│   ├── posterior_param_draws_ranked.mat
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

Datasets/ dicts/ structs usually go GROUP × MODEL × SUBJECT.


**NB**
Oedema paper submitted June 2025. When IB was modelling preliminary data for other project (July 2025); spotted typos in stan priors. Investigating these coincided with the receipt of the Oedema paper review; where it was decided to split the postop data by site. IB wrote this repo; all based on TG & WG's work from [Gilmour et.al.](https://doi.org/10.1093/brain/awae025).

 
### Models  `./Stan`

All models are originally written by Will Gilmour, see [Gilmour et.al.](https://doi.org/10.1093/brain/awae025).\
**No changes** to the models or decision rules. 
However stan code has been updated from pyStan to cmdPyStan (eg. array syntax) and priors/ hyperparameters have been updated (Isla Barnard, 2025). 

### Fitting `./Fitting`

`./Fitting/fitting.ipynb` reformats the behavioural data from concatenated `.csv` format,
Compiles & fits Stan models (see `Stan/stan-models`):

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

*There are occasional divergent transitions in the fits; more commonly in the delta rule models, contact authors for details (addressing these was out of scope in this refit).*\
`cmdPyStan` fits are written out as `.csv`  into `fits/[group]/[model]/[model_name]-YYYYMMDDHHMMSS_CHAIN.csv` so e.g. `AlphaSME_model-20251009150541_4.csv` is the 4th chain of one of our runs in early October 2025. 

`./Fitting/analysis.ipynb` loads fits and converts to [Arviz](https://python.arviz.org/en/stable/) inference data objects for a quick check of posteriors and formats. Parameters of interest are written out to MATLAB as `per_subject_draws.mat`. 

If you run fits and abort mid run (or ran more than one fit without redirecting output), there may be extra csvs in `fits/[group]/[model]/` that could cause issues in the postprocessing code (so just remove from the directory given to `./Fitting/analysis.ipynb` instead).


## Model comparison  `./ModelComparison`

Suggest using the parfor for significant speedup to calculate the log-likelihood (suppress/ignore broadcast var warnings and keep an eye on RAM). 

See `model_comparison.m` script and `model_comparisons.mat`; which contains several different ways of asking the data which was model the best fit. 

### Bayes Information Criterion and Liklihood Per Trial 

After running though PSIS-LOO for model comparison (standard in field) found the pareto k-values were as follows (see [here](https://mc-stan.org/loo/reference/pareto-k-diagnostic.html) for more). 

         Group         k < p7    0.7< k < 1    k > 1
    _______________    ______    __________    _____

    "HC"                 10         125         121 
    "PreTreat"            8         169         119 
    "PostTreat"           6         149         141 
    "PostTreat_Liv"       4          35          57 
    "PostTreat_Dun"       4          96         100 


PSIS-LOO asks 'how well does each model predict unseen data better (without penalising for additional parameters)?'. But though Post-Op Dundee patients have different parameters, on average, than eg Healthy Controls; given our sample sizes and intrapatient variability a new post-op patient's parameters wouldn't be predictable from other post-op patients. So in our dataset we find PSIS-LOO gives almost all pareto k-values > 0.7 (also PSIS-LOO (& WAIC); both CV approximations, are very close to the simple mean of the likelihoods- see `model_comparisons.mat`).   
We don't need to ask for a LOO-CV approximation (and we don't have time to re run LOO-CV)- we are asking 'which model generated this data?' Or 'of the cognitive algorithms that are our best guess, when we offer them up to the data, which describes the data best?

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


## Model Metrics `./ChoiceAnalysis`

To complete with TG's codes for e.g. P(stay) & P(choose best bandit). 

**Choice Classification**

The script `choice_classification.m` uses the Kalman Filter representation of value to classify behavioural choices into Exploitative, Directed Explorative or Random Explorative. 
As before; algorithm originally written by Will Gilmour, see [Gilmour et.al.](doi.org/10.1093/brain/awae025) and was adapted for this refit. 

## Parameter Recovery `./ParameterRecovery`

NB: IB didn't know which model had 'won' (or what that really meant, see discussion above) so ran parameter recovery on all 4 'best' models (AlphaSMP, AlphaSMEP, BayesSMP, BayesSMEP). So some delta rule data is in structs (but is unused in the revision); and some are stored within `./ParameterRecovery/AlphaParameterRecovery/`. 

**Posterior Sampling**

We sampled the posterior to test parameter recovery across typical (not exceptional) posterior fits (rather than the means of posterior params). 
The script `posterior_param_draw_ranks.m` selects K=5 posterior draws. For each subject, the 10000 draws are ranked by log likelihood value, top & bottom 10% are excluded, retaining draws ranked 1001:9000); and from this bulk of the posterior mass, 5 evenly spaced draws are selected, and the posterior parameter values sampled and stored in `posterior_param_draws_ranked.mat`. 

**Behavioural Data Simulation**

The notebook `parameter_recovery_simulation_BAYES.ipynb` loads in behavioural data to obtain each participants walks. Per participant, 3 repeats of each of the K-5 samples are simulated using stan (`./Stan/stan_simulations/`) (a total of 15 per participant). The simulated data are stored in `./simulated_data/YYYY-MM-DD-HH-MM-SS-simulations` and within this the simulated behavioural data is stored as `simulations_stan_struct.mat` (and also the stan generated .csvs are retained). There is a matplotlib plotting function at the end of the notebook if needed. 

**Simulated Behavioural Data Fitting**

As before, we do parallelised stan fits in `parameter_recovery_fitting_BAYES.ipynb`. On our i9 24-core machine we can refit the 15 simulated sets from a single participant in approx, 25-45 minutes on the 4 cores (1 chain per core). 

We used empirical Bayes (not hierarchical) with priors taken from the distributions of the grand means of the posteriors, over all groups (see  (`./Stan/stan_simulations/`) . Though not included in the published analysis; the parameter recovery poor for some of the delta learning rule parameters (especially alpha; which just regressed to the prior). We understand this can be better recovered by setting the initial value to [0,0,0,0]; but refitting was out of scope as the delta rules were not the winning models). 

Here, fits are in `fits/[group]/[model]/[subject]/[model_name]-YYYYMMDDHHMMSS_CHAIN.csv`. Again if you run the fits and abort mid run, there may be extra csvs in `fits/[group]/[model]/[subject]/` that could cause issues in the postprocessing code. 

`parameter_recovery_formatting.ipynb` formats the .csv stan fits for MATLAB, and parameters of interest are stored in  `parameter_recovery_draws.mat`. 

**Parameter Recovery Analysis**
`simulations_stan_struct.mat` and `parameter_recovery_draws.mat` are loaded into MATLAB using `parametter_recovery.m` which calculates the means and the HDI for each simulated parameter; storing this in `param_recovery_summary_stats.mat`. There is a plotting file (ChatGPT generated) to check these in `plot_param_recovery.m`, 


