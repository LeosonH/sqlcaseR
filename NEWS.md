# *News*
# sqlcaseR 0.2.1 (2025-9-8)

* Added support for different quote types and NULL handling strategies
* Implemented flexible column selection by name or index
* File validation - check if files exist before reading
* Input type validation - Ensure inputs are data frames or valid file paths
* Data validation - Check for empty data, sufficient columns, valid column names
* NA handling - Skip rows with NA values and warn users
* SQL injection protection - Escape single quotes in string values
* Better error messages - More descriptive error messages for troubleshooting
* Graceful degradation - Continue processing when possible, skip problematic row

# sqlcaseR 0.2.0 (2023-11-21)

* New function! updatetable() creates a SQL UPDATE...SET...WHERE query from a
CSV file or dataframe that includes the values to be updated in the SQL table.

# sqlcaseR 0.1.3 (2023-1-15)

* New function! inlist() creates a SQL IN() list from a CSV file or dataframe
that includes the values to check for.

# sqlcaseR 0.1.2 (2022-12-22)

* Added header argument to specify if input file has a header row.
* Added error message for unspecified inputs.

# sqlcaseR 0.1.1 (2022-12-20)

* Added functionality to read in dataframes in addition to file paths.

# sqlcaseR 0.1.0 (2022-12-16)

## Initial Release to GitHub

* Initial Release to GitHub
