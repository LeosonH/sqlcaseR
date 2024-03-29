# sqlcaseR
## sqlcaseR: A long CASE WHEN THEN statement constructor for SQL interfaces in R
**Version 0.2.0**

***Leoson Hoay <br>21 Nov 2023***


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

This function constructs a CASE WHEN THEN statement from a mapping CSV file or
R dataframe It assumes that the first column of the data contains the original
WHEN values, and the second column contains the THEN values (the values
to be mapped to.)

**Usage**

casewhen(inputfile=NULL, header=FALSE)

**Arguments**

*inputfile* R dataframe or path to the mapping file

*header* If reading a CSV file, specify TRUE if there is a header row, FALSE if
there is no header row.

**Value**

A string that represents the constructed CASE statement

<br>
***inlist()***

**description**

This function constructs a IN statement from a mapping CSV file or
R dataframe. It assumes that the first column of the data contains the vector of
values that the IN statement will check against.

**Usage**

inlist(inputfile=NULL, header=FALSE)

**Arguments**

*inputfile* R dataframe or path to the mapping file

*header* If reading a CSV file, specify TRUE if there is a header row, FALSE if
there is no header row.

**Value**

A string that represents the constructed IN statement.

<br>
***updatetable()***

**description**

This function constructs an UPDATE statement from a mapping CSV file or
R dataframe. It assumes that the first column of the data contains the key column
and the keys to be checked against, and assumes that the rest of columns 
contain the columns and values to be updated into the table.

**Usage**

updatetable(inputfile=NULL, tablename=NULL)

**Arguments**

*inputfile* R dataframe or path to the mapping file

*tablename* Name of the SQL table to be updated.

**Value**

A string that represents the constructed UPDATE statement.


## Installation

Install using:

```{}
devtools::install_github("leosonh/sqlcaser")
```

## Acknowledgments
Much thanks to a couple of my colleagues at [Learning Collider](https://www.learningcollider.org/) - Nitya Raviprakash
and Jasmin Dial - who provided healthy discussion around my misery of
constructing long SQL queries. Credit is also due to Kevin Flerlage, whose
efforts in automating this process in Excel should be commended and partially
inspired this package.

## Citation and License
If desired, cite the package using:

```{}
citation("sqlcaser")
```

License: MIT License
