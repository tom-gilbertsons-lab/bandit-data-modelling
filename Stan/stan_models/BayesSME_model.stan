// changes to code from doi.org/10.1093/brain/awae0252024
//      isla july2025/oct2025 reformatted (to array syntax) for cmdStanPy
//      isla oct2025 pulled priors for hyperparameters out of loop
//      (see https://discourse.mc-stan.org/t/hierarchical-model-behavioural-data-should-param-standard-deviation-priors-be-group-level-or-inside-per-subject-loop/40148/2)

// Define the data types
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
  real<lower=0,upper=3> beta_mu;      // Mean of beta
  real<lower=-20,upper=20> phi_mu;    // Mean of phi

  real<lower=0> beta_sd;              // Standard deviation of beta
  real<lower=0> phi_sd;               // Standard deviation of phi
  
  array [nSubjects] real<lower=0,upper=3> beta;   // beta for each subject
  array [nSubjects] real<lower=-20,upper=20> phi; // phi for each subject
  }

// The model section where the log-likelihood is incrementally constructed
model {
  beta_sd    ~ cauchy(0,1);  // Prior for beta standard deviation
  phi_sd     ~ cauchy(0,1);  // Prior for phi standard deviation

  for (s in 1:nSubjects) {   // Loop over subjects

    vector[4] v;   // Value (mu)
    vector[4] sig; // Sigma
    vector[4] eb;  // Exploration bonus
    real pe;       // Prediction error
    real Kgain;    // Kalman gain

    v   = rep_vector(v1, 4); // Initialize v with prior belief mean reward value
    sig = rep_vector(sig1, 4); // Initialize sig with prior belief variance

    beta[s]    ~ normal(beta_mu, beta_sd);          // Prior for beta
    phi[s]     ~ normal(phi_mu, phi_sd);            // Prior for phi

    // Loop over trials
    for (t in 1:nTrials) {        
      
      if (choice[s,t] != 0) { // If a choice was made
        
        eb = phi[s] * sig;   // Compute exploration bonus
        
        // Compute action probabilities
        choice[s,t] ~ categorical_logit( beta[s] * (v + eb)); 
        
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
