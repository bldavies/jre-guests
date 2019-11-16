# *JRE* guests

This repository contains the source data for [my blog post on popularity spikes following guests' appearances on *The Joe Rogan Experience*][post-url] (*JRE*).
I collected these data at 9:50am NZST on September 18, 2018 using the R scripts in `code/`.

## File descriptions

`code/episodes.R` scrapes [the *JRE* podcast directory](http://podcasts.joerogan.net) for a list of episode numbers, dates and titles, and cleans these data by, e.g., filling in missing episode numbers and removing non-ASCII characters from episode titles.

`code/guests.R` generates a (manually adjusted) list of guests who appear on each *JRE* episode identified in `data/episodes.csv`.

`code/popularity.R` downloads Google Trends data (based on web search interest in the United States) for each unique value of `guest_name` in `data/guests.csv`.

I ran each script in a fresh instance of `jre-guests.Rproj`.

## Dependencies

I used the [httr](https://cran.r-project.org/package=httr) and [rvest](https://cran.r-project.org/package=rvest) packages to scrape episode metadata, [gtrendsR](https://cran.r-project.org/package=gtrendsR) to download Google Trends data, [zoo](https://cran.r-project.org/package=zoo) to compute rolling means, and various packages from the [tidyverse](https://www.tidyverse.org) to read, manipulate and write data.
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

The contents of `code/` are licensed under the [MIT license](https://github.com/bldavies/jre-guests/blob/master/LICENSE).

[post-url]: https://bldavies.com/blog/jre-guests/
