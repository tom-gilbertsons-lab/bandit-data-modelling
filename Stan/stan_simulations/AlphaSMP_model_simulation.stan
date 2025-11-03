// Author:I Barnard 2025
// Alpha Learner with Perseveration only model simulation
// AlphaSMP_model_simulation.stan
data {
  int<lower=1> nSubjects;
  int<lower=1> nTrials;
  array[nTrials, 4] real<lower=0, upper=100> reward;
  array[nSubjects] real<lower=0, upper=1> alpha; 
  array[nSubjects] real<lower=0, upper=3> beta; 
  array [nSubjects] real persev; 
  }

transformed data {
  real<lower=0, upper=100> Q1;
  
  Q1 = 50.0;
}


generated quantities {
  array[nSubjects, nTrials] int choice;
  array[nSubjects, nTrials] real reward_obt;
  for (s in 1:nSubjects) {
      vector[4] Q;   // value (v)
      vector[4] pb;  // perseveration bonus
      real pe;       // prediction error
  
      Q = rep_vector(Q1, 4);
        
      for (t in 1:nTrials) {        
        pb = rep_vector(0.0, 4); // Reset Perseveration bonus

        if (t>1) {
            pb[choice[s,t-1]] = persev[s]; // Bandit last chosen gets bonus
        }
        
        choice[s,t] = categorical_logit_rng( beta[s] * (Q + pb )); // generate action probabilities and select an action
        reward_obt[s,t] = reward[t,choice[s,t]]; // reward obtained based on choice simulated
  
        pe = reward_obt[s,t] - Q[choice[s,t]];          // prediction error 
        Q[choice[s,t]] = Q[choice[s,t]] + alpha[s]*pe;  // value updating
      }
    }
}  
