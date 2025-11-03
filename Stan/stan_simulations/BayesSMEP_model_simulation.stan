// Author: Will Gilmour 2024 
// Bayesian Learner with Perseveration and exploration bonus model simulation
// BayesSMEP_model_simulation.stan
data {
  int<lower=1> nSubjects;
  int<lower=1> nTrials;
  array[nTrials, 4] real<lower=0, upper=100> reward;
  array[nSubjects] real<lower=0, upper=3> beta; 
  array [nSubjects] real phi; 
  array [nSubjects] real persev; 
  }

transformed data {
  real<lower=0, upper=100> Q1;
  real<lower=0> sig1;
  real<lower=0> sigO;
  real<lower=0> sigD;
  real<lower=0,upper=1> decay;
  real<lower=0, upper=100> decay_center;
  
  // random walk parameters 
  Q1   = 50.0;        // prior belief mean reward value trial 1
  sig1 = 4.0;         // prior belief variance trial 1
  sigO = 4.0;         // observation variance
  sigD = 2.8;         // diffusion variance
  decay = 0.9836;     // decay parameter
  decay_center = 50;  // decay center
}


generated quantities {
  array[nSubjects, nTrials] int choice;
  array[nSubjects, nTrials] real reward_obt;
  for (s in 1:nSubjects) {
      vector[4] Q;   // value (Q)
      vector[4] sig; // sigma
      vector[4] eb;  // exploration bonus
      vector[4] pb;  // perseveration bonus
      real pe;       // prediction error
      real Kgain;    // Kalman gain
  
      Q   = rep_vector(Q1, 4);
      sig = rep_vector(sig1, 4);
        
      for (t in 1:nTrials) {        
        eb = phi[s] * sig; // update Exploration bonus
        pb = rep_vector(0.0, 4); // Reset Perseveration bonus

        if (t>1) {
            pb[choice[s,t-1]] = persev[s]; // Bandit last chosen gets bonus
        }
        
        choice[s,t] = categorical_logit_rng( beta[s] * (Q + eb + pb )); // generate action probabilities and selection an action based on this
        reward_obt[s,t] = reward[t,choice[s,t]]; // reward obtained based on choice simulated
  
        pe    = reward_obt[s,t] - Q[choice[s,t]];                       // prediction error 
        Kgain = sig[choice[s,t]]^2 / (sig[choice[s,t]]^2 + sigO^2); // Kalman gain
        
        Q[choice[s,t]]   = Q[choice[s,t]] + Kgain * pe;             // value/mu updating (learning)
        sig[choice[s,t]] = sqrt( (1-Kgain) * sig[choice[s,t]]^2 );  // sigma updating
      
      Q = decay * Q + (1-decay) * decay_center;  
        for (j in 1:4) {
          sig[j] = sqrt( decay^2 * sig[j]^2 + sigD^2 );
        }
      }
    }
}  
