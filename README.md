## Code for "A Simple Threshold Captures the Social Learning of Conventions"

Please email any / all of the (co-first) authors if you have questions.
- **Spencer Caplan** scaplan@gc.cuny.edu
- **Douglas Guilbeault** dguilb@stanford.edu
- **Charles Yang** charles.yang@ling.upenn.edu

### Preprint

[available on OSF]([https://github.com/user/repo/blob/branch/other_file.md](https://osf.io/preprints/psyarxiv/xucka_v1))


---

## Setup

* **Bash** tested on GNU bash, **version 3.2.57**(1)-release (arm64-apple-darwin23)
* **Python** tested on **version 3.11.8** with no external libraries.
* **R** scripts have been tested on **version 4.3.1**. The following R packages are required to create the plots and run statistical analysis. ```
  dplyr, tidyr, ggplot2, Hmisc, scales, Matrix, tibble, lme4, reshape2, tidyverse, cowplot, ggpubr, ggrepel, xtable, ggtext```
  - The scripts will attempt to install them automatically, though in my experimence it is far preferred to ensure that these are present and available on the local system ahead of time.

No other setup is required.

***n.b.*** a number of scripts assume a Unix-style directory stucture (already satisfied on Linux or Mac OS systems). You may need to make some manual adjustments if running on Windows (or, perhaps easier, would be to run using "linux subsystem for windows" if this applies to you).


## Running

The following script runs all generation and analysis:

```
$ runall.sh
```
