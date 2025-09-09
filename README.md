# sqlcaseR
## sqlcaseR: A long CASE WHEN THEN statement constructor for SQL interfaces in R
**Version 0.2.1**

***Leoson Hoay <br>Last Updated: 9 Sep 2025 (0.2.0 to 0.2.1)***


## Introduction
This module was born out of my genuine frustration while constructing an
extremely long CASE WHEN...THEN statement to re-label categorical variables.
It is most helpful for folks who intend to work with SQL directly in the R
environment, likely with a SQL connector such as RODBC or RSQLite. 

Instead of manually inputting WHENs and THENs to replace/map values, this
library does it for you if you provide it with a mapping CSV file that contains
the original values in the first column, and the values to map to in the second
column. This version only supports CSV files for now, but support for other file
formats is planned.

<br>
Go from this:
                  
| | |
|--------------------------------|-------------------------------|
| Hotel/Motel	                   | Living in Shelter/Hotel/Motel |
| Homeless Shelter	             | Living in Shelter/Hotel/Motel |
| Homeless Status Not Applicable | Not Homeless                  |
| N/A	                           | Not Homeless                  |
| No	                           | Not Homeless                  |
| Homeless, Doubled-Up	         | Doubled Up                    |

To this:

```{}
CASE WHEN 'Hotel/Motel' THEN 'Living in Shelter/Hotel/Motel'
 WHEN 'Homeless Shelter' THEN 'Living in Shelter/Hotel/Motel'
 WHEN 'Homeless Status Not Applicable' THEN 'Not Homeless'
 WHEN 'N/A' THEN 'Not Homeless'
 WHEN 'No' THEN 'Not Homeless'
 WHEN 'Homeless, Doubled-Up' THEN 'Doubled Up'
```

As of version 0.2.0, the package also supports the creation of long SQL IN()
lists via the *inlist()* function. This was inspired by reading about Kevin
Flerlage's [Excel implementation](https://www.flerlagetwins.com/2020/09/in-operator-generator-case-statement.html). 
It also supports the creation of SQL UPDATE functions via the *updatetable()* method.

## Demonstration

```{r setup}
library(sqlcaser)
```

The package assumes that the user has a mapping CSV file or an R dataframe
similar to the example below: 

```{r}
samp <- system.file("extdata", "sample.csv", package = "sqlcaser")
mapping <- read.csv(samp)
mapping
```

The function **casewhen()** takes an ***R dataframe or the file path of the
mapping file*** as input,and returns the CASE statement as a string, while printing
it to the console as well.

```{r}
statement <- casewhen(samp)
```

The user can then easily include it as part of the SQL query:

```{r}
query <- paste("SELECT id, ", statement, " END AS status "," \nFROM table;")
cat(query)
```

## Sample Data
A sample mapping file is provided in this package. The file path can be accessed
as follows:

```{r}
samplepath <- system.file("extdata", "sample.csv", package = "sqlcaser")
```

## Functions

***casewhen()***

**description**

This function constructs a CASE..WHEN..THEN statement from a mapping file or
dataframe. By default, it uses the first column for WHEN values and second
column for THEN values, but you can specify different columns.

**Usage**

casewhen(
  inputfile = NULL,
  header = FALSE,
  when_col = 1,
  then_col = 2,
  else_value = NULL,
  quote_type = "single",
  handle_nulls = "skip"
)

**Arguments**

*inputfile* Mapping dataframe OR path to the mapping file

*header* If reading a csv file, TRUE if the file includes a header row,
FALSE if it does not include a header row.

*when_col* Column name or index for WHEN values (default: 1)

*then_col* Column name or index for THEN values (default: 2)

*else_value* Optional ELSE value for the CASE statement

*quote_type* Type of quotes to use: "single", "double", or "auto" (default: "single")

*handle_nulls* How to handle NULL/NA values: "skip", "null", or "error" (default: "skip")

**Value**

A string that represents the constructed CASE statement

<br>
***inlist()***

**description**

This function constructs an IN statement from a mapping file or
dataframe. By default it uses the first column, but you can specify
a different column by name or index.

**Usage**

inlist(
  inputfile = NULL,
  header = FALSE,
  value_col = 1,
  quote_type = "single",
  handle_nulls = "skip",
  distinct = TRUE
)

**Arguments**

*inputfile* R dataframe or path to the mapping file

*header* If reading a CSV file, specify TRUE if there is a header row, FALSE if
there is no header row.

*value_col* Column name or index for IN values (default: 1)

*quote_type* Type of quotes to use: "single", "double", or "auto" (default: "single")

*handle_nulls* How to handle NULL/NA values: "skip", "null", or "error" (default: "skip")

*distinct* Remove duplicate values if TRUE (default: TRUE)

**Value**

A string that represents the constructed IN statement.

<br>
***updatetable()***

**description**

This function constructs UPDATE statements from a mapping file or
dataframe. By default, it uses the first column as the key column for WHERE clauses,
and updates all other columns. You can specify which columns to use.

**Usage**

updatetable(
  inputfile = NULL,
  tablename = NULL,
  key_col = 1,
  update_cols = NULL,
  quote_type = "auto",
  handle_nulls = "skip",
  batch_updates = TRUE
)

**Arguments**

*inputfile* R dataframe or path to the mapping file

*tablename* Name of the SQL table to be updated.

*key_col* Column name or index for WHERE clause key (default: 1)}

*update_cols* Vector of column names/indices to update (default: all except key_col)

*quote_type* Type of quotes to use: "single", "double", or "auto" (default: "auto")

*handle_nulls* How to handle NULL/NA values: "skip", "null", or "error" (default: "skip")

*batch_updates* If TRUE, create one UPDATE per row; if FALSE, create one per column (default: TRUE)

**Value**

A string that represents the constructed UPDATE statement.


## Installation

Install using:

```{}
devtools::install_github("leosonh/sqlcaser")
```

## Acknowledgments
Much thanks to a couple of my prior colleagues at [Learning Collider](https://www.learningcollider.org/) - Nitya Raviprakash
and Jasmin Dial - who provided healthy discussion around my misery of
constructing long SQL queries. Credit is also due to Kevin Flerlage, whose
efforts in automating this process in Excel are commendable and partially
inspired this package.

## Citation and License
If desired, cite the package using:

```{}
citation("sqlcaser")
```

License: MIT License
