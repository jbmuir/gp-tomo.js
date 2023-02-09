### The anti-computational earth science meeting

- My dream was to create a fully Bayesian nonlinear surface wave tomography with no MCMC
- How far can we go without doing any "big" computations? 



### Typical inverse problem setups

We have
  - data `$d$`
  - model parameters `$m$`
  - prediction function `$G$`
  - prior `$p(m)$`
  - likelihood `$p(d|m) = L(G(m)-d)$` for function `$L$`

and we combine them with Bayes' rule `$$p(m|d) \propto p(d|m)p(m)$$`



### The surface wave setup

For surface waves, we normally split the inverse problem into 2 parts:

  - Construct `$C_p$` and `$C_g$` maps from surface measurements. `$G$` is nonlinear ray bending
  - Do 1D inversions for structure using these maps. `$G$` is a surface wave eigenfunction code.
  
The first part can be a "big" data problem — thousands of sources and stations.  



### Eikonal tomography: velocities without the inverse problem

For *weakly varying media* the phase delay of a single wavefront obeys the eikonal equation:
`$$ | \nabla \tau(x)| = c(x)^{-1} $$`
If we can measure the phase delay `$\tau$`, we immediately get the phase velocity `$c$`. 



### Eikonal tomography: velocities without the inverse problem

No inverse problem means:
  - fast, 
  - parallelizable,
  - interpretable

>*Lin et al. 2009 claim:* there is no explicit regularization and, hence, the method is largely free from *ad hoc* choices

Note: but of course now the phase delay calculation controls everything



### How to fit `$\tau$`?

The idea for this project is to use a Gaussian Process (GP) to fit `$\tau$`. 

GPs are priors on function space, defined by mean `$f(x)$` and covariance `$k(x,x')$`. 

For data `$y$` collected at `$X$` and predicted at `$X'$`, the GP posterior of phase delay `$\tau$` is 
`$$ \tau({X}') | {y} \sim N(\tau_0({X}') + K_{{X}'{X}}(K_{{X}{X}} + \sigma^2I)^{-1}({y}-\tau_0({X})), \\ K_{{X}'{X}'}-K_{{X}'{X}}(K_{{X}{X}} + \sigma^2I)^{-1}K_{{X}{X}'}). $$`


### Coding up a basic GP
<iframe src="http://localhost:1234" width="100%" height="600"></iframe>



### Fitting a 1D Gaussian process

Here we use a squared exponential kernel `$\rho^2\exp(-(x-x')^2 / (2l^2))$` with data noise `$\sigma$`
<iframe src="http://localhost:8001" width="100%" height="600"></iframe>



### Derivative of a GP is a GP

>The equation is a bit too long, but the general idea is that since derivatives are linear operations they commute with expectations (linear) and covariances (bilinear).




### Plotting the derivative

Here we use a squared exponential kernel `$\rho^2\exp(-(x-x')^2 / (2l^2))$` with data noise `$\sigma$`
<iframe src="http://localhost:8002" width="100%" height="600"></iframe>



### What does this look like for eikonal tomography? 
<img src="resources/gp_reconstruction.pdf"  width="60%" >



### Sampled phase delay is better than a spline fit
<img src="resources/gp_spline.pdf"  width="60%" >



### Sampled slowness is better than a spline fit 
<img src="resources/gp_k2.pdf"  width="60%" >




### Saddlepoint approximations of the posterior
We still don't have an analytic formula for `$C_p$`. Unfortunately it is impossible — but we can use some spooky tricks to get close

<img src="resources/Five_Pointed_Star_Lined.svg"  width="30%">



### Saddlepoint approximations of the posterior

Given some random variable `$X$`, consider the cumulant generating function 

`$ K_X(s) = log \int_X e^{s x}f(x)dx$`

then

`$ f(x) \sim \sqrt{\frac{1}{2\pi K''(\hat{s})}} e^{K(\hat{s})-\hat{s}x}$`

where `$K'(\hat{s}) = x$`.



### Saddlepoint applied to eikonal tomography is excellent

<img src="resources/gp_sp_approx.pdf"  width="60%" >



### Conclusions

  - GPs are fun
  - Saddlepoint approximations are spooky
  - Reactive notebooks are safer and more fun than e.g. Jupyter