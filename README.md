## Code for "A Simple Threshold Captures the Social Learning of Conventions"

Please email any / all of the (co-first) authors if you have questions.
- **Spencer Caplan** scaplan@gc.cuny.edu
- **Douglas Guilbeault** dguilb@stanford.edu
- **Charles Yang** charles.yang@ling.upenn.edu

### Preprint available below:
- [PsyArXiv](https://osf.io/preprints/psyarxiv/xucka_v1)
- [SocArXiv (pending)](https://osf.io/preprints/socarxiv/evnq7_v1?view_only=)

---

## Setup

* **Bash** tested on GNU bash, **version 3.2.57**(1)-release (arm64-apple-darwin23)
* **Python** tested on **version 3.11.8** with no external libraries.
* **R** scripts have been tested on **version 4.3.1**. The following R packages are required to create the plots and run statistical analysis. ```
  dplyr, tidyr, ggplot2, Hmisc, scales, Matrix, tibble, lme4, reshape2, tidyverse, cowplot, ggpubr, ggrepel, xtable ```
  - The scripts will attempt to install them automatically, though in my experimence it is far preferred to ensure that these are present and available on the local system ahead of time.

No other setup is required.

***n.b.*** a number of scripts assume a Unix-style directory stucture (already satisfied on Linux or Mac OS systems). You may need to make some manual adjustments if running on Windows (or, perhaps easier, would be to run using "linux subsystem for windows" if this applies to you).


## Running

The following script runs all generation and analysis:

```
$ runall.sh
```



## Abstract

A persistent puzzle across the cognitive and social sciences is how people manage to learn social conventions from the sparse and noisy behavioral data of diverse actors, without explicit instruction. Here, we show that the dominant theories of social learning perform poorly at capturing how individuals learn conventions in canonical coordination experiments that task them with matching their behaviors while interacting in social networks. Across experiments, participants' learning behavior systematically deviates from both imitation and statistical optimization. Instead, we find that participants follow a categorical, two-stage learning process: they behave probabilistically until they acquire enough information about each other to trigger a mental threshold and then their behaviors stabilize. We precisely identify this threshold using the Tolerance Principle, a parameter-free equation first developed to model how children learn rules in language. Our simulations show that threshold-based agents often produce social learning that is more accurate than imitating and optimizing agents. We further show that the Tolerance Principle offers an improved model of how a critical mass of dissenting actors can overturn established conventions. The superior performance of our model holds when comparing against a variety of optimization approaches, including Bayesian inference. These findings offer compelling evidence that a simple, mathematical threshold underlies individual and social learning, from grammatical rules to behavioral conventions.
