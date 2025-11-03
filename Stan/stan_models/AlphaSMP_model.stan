// changes to code from doi.org/10.1093/brain/awae0252024
//      isla july2025/oct2025 reformatted (to array syntax) for cmdStanPy
//      isla oct2025 pulled priors for hyperparameters out of loop
//      (see https://discourse.mc-stan.org/t/hierarchical-model-behavioural-data-should-param-standard-deviation-priors-be-group-level-or-inside-per-subject-loop/40148/2)


// Defining the data that is inputted into the model
data {
  int<lower=1> nSubjects; // number of subjects
  int<lower=1> nTrials; // number of trials  
  array[nSubjects, nTrials] int<lower=0, upper=4> choice; // Choice data for each subject in each trial
  array[nSubjects, nTrials] real<lower=0, upper=100> reward; // Reward data for each subject in each trial
}

// Defining transformed data
transformed data {
  real<lower=0, upper=100> v1; // prior belief mean reward value trial 1
  
  v1 = 50.0;
}

// Defining parameters of the model
parameters {
  real<lower=0,upper=1> alpha_mu; // mean of learning rate
  real<lower=0,upper=3> beta_mu; // mean of inverse temperature
  real<lower=-20,upper=20> persev_mu; // mean of perseveration

  real<lower=0> alpha_sd; // standard deviation of learning rate
  real<lower=0> beta_sd; // standard deviation of inverse temperature
  real<lower=0> persev_sd; // standard deviation of perseveration
  
  array[nSubjects] real<lower=0, upper=1> alpha; // learning rate for each subject
  array [nSubjects] real<lower=0,upper=3> beta; // inverse temperature for each subject
  array [nSubjects] real<lower=-20,upper=20> persev; // perseveration for each subject

}

// Model specifications
model {

  alpha_sd ~ cauchy(0,1);
  beta_sd ~ cauchy(0,1);
  persev_sd ~ cauchy(0,1);
  
  for (s in 1:nSubjects) {
    vector[4] v; // value (mu)
    vector[4] pb; // perseveration bonus
    real pe; // prediction error

    v = rep_vector(v1, 4); // initialize value vector with prior belief mean reward
  
    // Prior distributions for parameters
    alpha[s] ~ normal(alpha_mu, alpha_sd);  
    beta[s] ~ normal(beta_mu, beta_sd);          
    persev[s] ~ normal(persev_mu, persev_sd);

    for (t in 1:nTrials) {
      if (choice[s,t] != 0) {

        pb = rep_vector(0.0, 4);        
        if (t>1) {
          if (choice[s,t-1] !=0) {
            pb[choice[s,t-1]] = persev[s]; // calculate perseveration bonus
          }
        }
  
        // Calculate action probabilities
        choice[s,t] ~ categorical_logit(beta[s] * (v + pb));
  
        // Calculate prediction error 
        pe = reward[s,t] - v[choice[s,t]];
  
        // Value/mu updating (learning)
        v[choice[s,t]] = v[choice[s,t]] + alpha[s] * pe;
      }
    }
  }
}
