
## Review of Behavioural Modeling for Thalamotomy Oedema (July & Oct 2025) 
#### Behavioural data modelling (splitting postop across Liverpool-Dundee) 



We jump between MATLAB and python here; `cmdPyStan` is used for modelling and have wrapped that in notebooks for ease (using `joblib` for parallelisation) and have used Arviz for initial plotting (however MATLAB is standard in field so structs <--> dicts throughout). 

The github repo does not have any data in it (see the .gitignore)
If you want these they are over in OSF at XXXX


#### General Notes 

IB: Isla Barnard\
WG: Will Gilmour\
TG: Tom Gilbertson
t.gilbertson@dundee.ac.uk\
https://github.com/tom-gilbertsons-lab


Directories with key datasets highlighted 
```
project_root/
├── README.md
├── ccn.yaml
├── Stan/
├── BehaviouralData/
├── Fitting/
├── ModelComparison/
└── ParameterRecovery/
```

Have provided ([IB's](https://github.com/i-brnrd)) conda env used for computational modelling of behavioural data as `ccn.yaml`.\
Recreate with `conda env create -n ccn -f ccn.yaml` and use via `conda activate ccn`. 

Datasets/ structs are generally organised as GROUP × MODEL × SUBJECT.


**NB**
When modelling the preliminary TN results (July 2025); some typos were spotted in the behavioural modelling (contact authors for details). Acceptance of these corrections coincided with the receipt of the Oedema paper review where it was decided to split the postop into Liverpool and Dundee as behavioural data (and scans) were taken at different times (Oct 2025). IB wrote this repo but it's all TG & WG's work. 

 
### Models  `./Stan`

All models are originally written by Will Gilmour, see [Gilmour et.al.](doi.org/10.1093/brain/awae025).\
**No changes** to the models or decision rules. 
However stan code has been updated from pyStan to cmdPyStan (eg. array syntax) and priors/ hyperparameters have been updated (Isla Barnard, 2025). 


### Fitting `./Fitting`

See `./Fitting/fitting.ipynb` &  `./Fitting/analysis.ipynb`

Reformats the behavioural data from concatenated `.csv` format as in [Gilmour et.al.](doi.org/10.1093/brain/awae025)\
Compiles Stan models (for easy parallelisation using `joblib` modules each job needs its own instance of the executable) and each model is fitted (see `Stan/stan-models`):

AlphaSM (Delta Rule)\
AlphaSME (+ exploration)\
AlphaSMP (+ perseveration)\
AlphaSMEP (+ exploration & perseveration)\
BayesSM (Kalman Filter)\
BayesSME (+ exploration)\
BayesSMP (+ perseveration)\
BayesSMEP (+ exploration & perseveration)

All using 
```
CHAINS= 4
nWarmup = 2500
nSamples = 2500
```

(There are occasional divergent transitions in the fits- more commonly in the delta rule models. Addressing these was out of scope in this refit). `cmdPyStan` fits are written out as `.csv`  into `fits/[group]/[model]/[model_name]-YYYYMMDDHHMMSS_CHAIN.csv` so e.g. `AlphaSME_model-20251009150541_4.csv` is the 4th chain of one of our runs. 

In `./Fitting/analysis.ipynb` the fits are loaded, converted to [Arviz](https://python.arviz.org/en/stable/) inference data objects for a quick check of posteriors and formats, then written out to MATLAB as `per_subject_draws.mat`. 

If you ran fits and aborted mid run, or ran more than one fit without redirecting output, there may be extra csvs in `fits/[group]/[model]/` that could cause issues in the postprocessing code (and can be removed from this directory instead).


## Model comparison  `./ModelComparison`

Suggest using the parfor for significant speedup to calculate the log likelihood (and suppress/ignore broadcast var warnings and keep an eye on RAM). 

See `model_comparison.m` script and `model_comparisons.mat`. 

### Bayes Information Criterion and Liklihood Per Trial 

After running though PSIS-LOO for model comparison, found the k-values indicated the psis-loo log liks were unreliable at best:

         Group         k < p7    0.7< k < 1    k > 1
    _______________    ______    __________    _____

    "HC"                 10         125         121 
    "PreTreat"            8         169         119 
    "PostTreat"           6         149         141 
    "PostTreat_Liv"       4          35          57 
    "PostTreat_Dun"       4          96         100 


This is not a surpise as PSIS-LOO asks 'which model predicts unseen data better'- we aren't really asking that; we are asking 'which model generated this data' i.e. of the cognitive algorithm we offer up to the data, which describes the data best?   
So post-op Dundee patients have different parameters, on average, than eg Healthy Controls but a new post-op patient's parameters wouldn't be predictable from other post-op patients. 

PSIS-LOO (& WAIC); both CV approximations, are very close to crude mean of the likelihoods (see `model_comparisons.mat`).

As per Wilson & Collins 2019, have included the BIC (Bayes Information Criterion) and the LPT (Liklihood per trial) as suggested by within authoritative 'Ten Simple Rules....' https://doi.org/10.7554/eLife.49547 

**Bayes Information Criterion (BIC)** (Appendix 2, Wilson & Collins 2019)



$$
\textrm{BIC} = -2 \: \ln\hat{\mathscr{L}} + k \: \ln T
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

The script `choice_classification.m` runs though the behavioural data and classifies; using Kalman Filter models of value encoding, choices into Exploitative, Directed Explorative or Random Explorative.   

As before; algorithm originally written by Will Gilmour, see [Gilmour et.al.](doi.org/10.1093/brain/awae025) and was adapted for this refit. 

## Parameter Recovery `./ParameterRecovery`

NB: During this section, IB didn't know which model had 'won' (see discussion above); due to time constraints, ran parameter recovery on all 4 'winning' models (AlphaSMP, AlphaSMEP, BayesSMP, BayesSMEP). Some delta rule data is in structs (but is unused in the revision) and some in `./ParameterRecovery/AlphaParameterRecovery/`. However many models, this is a larger HMC job than the model fitting.

**Posterior Sampling**

We employ a posterior sampling strategy to test parameter recovery across typical (not exceptional) posterior fits. 

The script `posterior_param_draw_ranks.m` selects K=5 posterior draws which are equally spaced across the central bulk of the likelihood distribution. 
For each subject, the 10000 draws are ranked by log likelihood value, top & bottom 10% are excluded, retaining draws ranked 1001:9000. 

From this bulk of the posterior mass, 5 evenly spaced draws are selected and the posterior parameter values sampled and stored in `posterior_param_draws_ranked.mat` to be used to simulate data. 

**Behavioural Data Simulation**

The notebook `parameter_recovery_simulation_BAYES.ipynb` loads in behavioural data in order to obtain the payoffs from each participants walks. Simulations are run using stan (`./Stan/stan_simulations/`) and we make 15 simulations per participant: 3 repeats of each of the K=5 samples from the posterior. 

The simulated daya are stored in `./simulated_data/YYYY-MM-DD-HH-MM-SS-simulations` and within this the stan `.csv`s are stored in directories as in a top level struct `simulations_stan_struct.mat` and there is a matplotlib plotting function at the end of the notebook if needed. 

**Simulated Behavioural Data Fitting**

As before, we do parallelised stan fits in a notebook `parameter_recovery_fitting_BAYES.ipynb`. On our i9 24-core machine we can refit the 15 simulated sets from a single participant in approx, 25-45 minutes on the 4 cores (1 chain per core). 

We used empirical Bayes (not hierarchical) with priors taken from the distributions of the grand means of the posteriors, over all groups (see  (`./Stan/stan_simulations/`) . Though not included in the published analysis; the parameter recovery was poor for some of the delta learning rule parameters (especially alphas, which just regressed to the prior). We understand this can be adjusted by setting the initial value to [0,0,0,0]; but doing so and rerunning was out of scope as the delta rules were not the winning models). 


Here, fits are in  `fits/[group]/[model]/[subject]` and as before fits are written out as `.csv`  into `fits/[group]/[model]/[model_name]-YYYYMMDDHHMMSS_CHAIN.csv` so e.g. `AlphaSME_model-20251009150541_4.csv` is the 4th chain of one of our runs. 
Again; if you run the fits and abort mid run, there may be extra csvs in `fits/[group]/[model]/` that could cause issues in the postprocessing code. 


We then load into `paramter_recovery_formatting.ipynb` to load into a MATLAB struct, `parameter_recovery_draws.mat`. 


