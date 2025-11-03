//  Author: I Barnard 2025
// Alpha Learner with Perseveration and exploration bonus model simulation
// AlphaSMEP_model_simulation.stan
data {
  int<lower=1> nSubjects;
  int<lower=1> nTrials;
  array[nTrials, 4] real<lower=0, upper=100> reward;
  array[nSubjects] real<lower=0, upper=1> alpha; 
  array[nSubjects] real<lower=0, upper=3> beta; 
  array [nSubjects] real phi; 
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
      vector[4] Q;    // value (Q)
      vector[4] LC;   // last chosen trial index
      vector[4] LCb;  // time since last chosen
      vector[4] eb;   // exploration bonus
      vector[4] pb;   // perseveration bonus
      real pe;        // prediction error
  
      Q  = rep_vector(Q1, 4);
      LC = rep_vector(0.0, 4);
        
      for (t in 1:nTrials) {        
        for (i in 1:4) LCb[i] = t - LC[i];
        eb = phi[s] * LCb;
        pb = rep_vector(0.0, 4);

        if (t>1) {
            pb[choice[s,t-1]] = persev[s];
        }
        
        choice[s,t] = categorical_logit_rng( beta[s] * (Q + eb + pb) );
        reward_obt[s,t] = reward[t,choice[s,t]];
  
        pe = reward_obt[s,t] - Q[choice[s,t]];
        Q[choice[s,t]] = Q[choice[s,t]] + alpha[s]*pe;

        LC[choice[s,t]] = t;
      }
    }
}  