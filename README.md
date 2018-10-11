# *JRE* guests

This repository contains the source material for [my blog post on popularity spikes following guests' appearances on *The Joe Rogan Experience*][post-url] (*JRE*).

## File descriptions

I performed my analysis in [RStudio](https://www.rstudio.com/) with R version 3.5.0.
I ran the scripts in `code/` in the order tabulated below, each within a fresh instance of `jre-guests.Rproj`.

File | Description | Output
--- | --- | ---
`episodes.R` | Scrapes [the *JRE* podcast directory](http://podcasts.joerogan.net) for a list of episode numbers, dates and titles, and cleans these data by, e.g., filling in missing episode numbers and removing non-ASCII characters from episode titles. | `data/episodes.csv`
`guests.R` | Generates a (manually adjusted) list of guests who appear on each *JRE* episode identified in `data/episodes.csv`. | `data/guests.csv`
`popularity.R` | Downloads Google Trends data (based on web search interest in the United States) for each unique value of `guest_name` in `data/guests.csv`. | `data/popularity.csv`
`analysis.R` | Generates the figures and table used in [my blog post][post-url]. | All files in `figures/` and `tables/`

The files in `data/` were last updated at 9:50am NZST on September 18, 2018.

## Dependencies

I used the [`httr`](https://cran.r-project.org/package=httr) and [`rvest`](https://cran.r-project.org/package=rvest) packages to scrape episode metadata, [`gtrendsR`](https://cran.r-project.org/package=gtrendsR) to download Google Trends data, [`zoo`](https://cran.r-project.org/package=zoo) to compute rolling means, and various packages from the [tidyverse](https://www.tidyverse.org) to read, manipulate and write data.
These dependencies can be installed by running

```r
install.packages(c("httr", "rvest", "gtrendsR", "zoo", "tidyverse"))
```

at the R console.
All other commands should be available through the base R installation.

## Legal notices

This repository contains data on episodes of *The Joe Rogan Experience*.
These episodes are the intellectual property of Joe Rogan and Talking Monkey Productions, and are protected by copyright.
I believe that my use of this intellectual property is covered by fair use.
Such use is intended to be educational and my derived commentary would be severely impaired without the copyrighted material.

Any use of the data contained in this repository is at the user's own legal risk.
I take no responsibility for the external use of these data, nor for any errors that they contain.

All repository content is licensed under the [MIT license](https://github.com/bldavies/jre-guests/blob/master/LICENSE).

[post-url]: https://bldavies.com/blog/jre-guests/
