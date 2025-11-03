// BayesSMEP_model.stan for Paramteer Recovery
// Empirical priors from posterior dist used (no heirarchical pooling)
// IB 2025

data {
  int<lower=1> nSubjects;                           // Number of subjects
  int<lower=1> nTrials;                             // Number of trials
  array[nSubjects, nTrials] int<lower=0, upper=4> choice; // Choice data for each subject in each trial
  array[nSubjects, nTrials] real<lower=0, upper=100> reward; // Reward data for each subject in each trial
}

// Define constants and initial values for the model
transformed data {
  real<lower=0, upper=100> v1;        // Prior belief mean reward value trial 1
  real<lower=0> sig1;                 // Prior belief variance trial 1
  real<lower=0> sigO;                 // Observation variance
  real<lower=0> sigD;                 // Diffusion variance
  real<lower=0,upper=1> decay;        // Decay parameter
  real<lower=0, upper=100> decay_center; // Decay center
  
  v1   = 50.0;
  sig1 = 4.0;
  sigO = 4.0;
  sigD = 2.8;
  decay = 0.9836;
  decay_center = 50;
}

// Define the parameters to estimate
parameters {
 
  array [nSubjects] real<lower=0,upper=3> beta;   // beta for each subject
  array [nSubjects] real<lower=-20,upper=20> phi; // phi for each subject
  array [nSubjects] real<lower=-20,upper=20> persev; // perseveration for each subject
}



// The model section where the log-likelihood is incrementally constructed
model {

  beta   ~ normal(0.12, 0.6);
  phi    ~ normal(0.0, 10.0); 
  persev ~ normal(12.0, 8.0);
  
  for (s in 1:nSubjects) {   // Loop over subjects

    vector[4] v;   // Value (mu)
    vector[4] sig; // Sigma
    vector[4] eb;  // Exploration bonus
    vector[4] pb;  // Perseveration bonus
    real pe;       // Prediction error
    real Kgain;    // Kalman gain

    v   = rep_vector(v1, 4); // Initialize v with prior belief mean reward value
    sig = rep_vector(sig1, 4); // Initialize sig with prior belief variance


 


    // Loop over trials
    for (t in 1:nTrials) {        
      
      if (choice[s,t] != 0) { // If a choice was made
        
        eb = phi[s] * sig;   // Compute exploration bonus
        pb = rep_vector(0.0, 4);  // Initialize perseveration bonus
        
        // If not the first trial
        if (t>1) {
          if (choice[s,t-1] !=0) { // If a choice was made in the previous trial
            pb[choice[s,t-1]] = persev[s]; // Update perseveration bonus
          }
        }
        
        // Compute action probabilities
        choice[s,t] ~ categorical_logit( beta[s] * (v + eb + pb )); 
        
        pe    = reward[s,t] - v[choice[s,t]];  // Compute prediction error 
        Kgain = sig[choice[s,t]]^2 / (sig[choice[s,t]]^2 + sigO^2); // Compute Kalman gain
        
        v[choice[s,t]]   = v[choice[s,t]] + Kgain * pe; // Update value/mu (learning)
        sig[choice[s,t]] = sqrt( (1-Kgain) * sig[choice[s,t]]^2 );  // Update sigma
        
      }
      
      v = decay * v + (1-decay) * decay_center;  // Apply decay to value/mu
      for (j in 1:4) {
          sig[j] = sqrt( decay^2 * sig[j]^2 + sigD^2 ); // Apply decay to sigma
      }
    }
  }  
}
