// AlphaSMP_model.stan for Parameter Recovery
// Rescorla–Wagner with perseveration only
// Pooling removed; empirical Bayes priors added

data {
  int<lower=1> nSubjects;
  int<lower=1> nTrials;
  array[nSubjects, nTrials] int<lower=0, upper=4> choice;
  array[nSubjects, nTrials] real<lower=0, upper=100> reward;
}

transformed data {
  real<lower=0, upper=100> v1;
  v1 = 50.0;
}

parameters {
  array[nSubjects] real<lower=0, upper=1>  alpha;    // learning rate
  array[nSubjects] real<lower=0, upper=3>  beta;     // inverse temperature
  array[nSubjects] real<lower=-20, upper=20> persev; // perseveration
}

model {
  // loose empirical Bayes priors around parameter posteriors
  alpha  ~ normal(0.85, 0.20);   
  beta   ~ normal(0.105, 0.03); 
  persev ~ normal(12.0, 8.0);     

  for (s in 1:nSubjects) {
    vector[4] v;
    vector[4] pb;
    real pe;

    v = rep_vector(v1, 4);

    for (t in 1:nTrials) {
      if (choice[s,t] != 0) {

        pb = rep_vector(0.0, 4);
        if (t > 1 && choice[s,t-1] != 0) pb[choice[s,t-1]] = persev[s];

        choice[s,t] ~ categorical_logit(beta[s] * (v + pb));

        pe = reward[s,t] - v[choice[s,t]];
        v[choice[s,t]] = v[choice[s,t]] + alpha[s] * pe;
      }
    }
  }
}
