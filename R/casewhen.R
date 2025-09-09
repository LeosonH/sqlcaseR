#' Generate a SQL CASE statement from a mapping file
#'
#' This function constructs a CASE..WHEN..THEN statement from a mapping file or
#' dataframe. By default, it uses the first column for WHEN values and second
#' column for THEN values, but you can specify different columns.
#'
#' @param inputfile Mapping dataframe OR path to the mapping file
#' @param header If reading a csv file, TRUE if the file includes a header row,
#' FALSE if it does not include a header row.
#' @param when_col Column name or index for WHEN values (default: 1)
#' @param then_col Column name or index for THEN values (default: 2) 
#' @param else_value Optional ELSE value for the CASE statement
#' @param quote_type Type of quotes to use: "single", "double", or "auto" (default: "single")
#' @param handle_nulls How to handle NULL/NA values: "skip", "null", or "error" (default: "skip")
#' @return A string that represents the constructed CASE statement
#' @export
#' @examples 
#'  input <- data.frame(Training = c("Strength", "Stamina", "Other"), 
#'                      Duration = c(60, 30, 45))
#'  result <- casewhen(inputfile = input, when_col = "Training", 
#'                     then_col = "Duration", else_value = "Unknown")
casewhen <- function(inputfile = NULL, header = FALSE, when_col = 1, then_col = 2, 
                     else_value = NULL, quote_type = "single", handle_nulls = "skip"){
  if (is.null(inputfile) == TRUE) {
    stop("Please include a file path or an input dataframe.")
  }
  
  # Validate parameters
  if (!quote_type %in% c("single", "double", "auto")) {
    stop("quote_type must be one of: 'single', 'double', 'auto'")
  }
  
  if (!handle_nulls %in% c("skip", "null", "error")) {
    stop("handle_nulls must be one of: 'skip', 'null', 'error'")
  }
  
  if (is.character(inputfile)) {
    if (!file.exists(inputfile)) {
      stop("File does not exist: ", inputfile)
    }
    tryCatch({
      mapping <- utils::read.csv(inputfile, header = header)
    }, error = function(e) {
      stop("Error reading file: ", e$message)
    })
  } else {
    if (!is.data.frame(inputfile)) {
      stop("Input must be a data frame or file path.")
    }
    mapping <- inputfile
  }
  
  if (nrow(mapping) == 0) {
    stop("Input data is empty.")
  }
  
  if (ncol(mapping) < 2) {
    stop("Input data must have at least 2 columns (WHEN and THEN values).")
  }
  
  # Resolve column references
  when_idx <- if (is.character(when_col)) {
    which(colnames(mapping) == when_col)
  } else {
    when_col
  }
  
  then_idx <- if (is.character(then_col)) {
    which(colnames(mapping) == then_col)
  } else {
    then_col
  }
  
  if (length(when_idx) == 0 || when_idx < 1 || when_idx > ncol(mapping)) {
    stop("Invalid when_col: ", when_col)
  }
  
  if (length(then_idx) == 0 || then_idx < 1 || then_idx > ncol(mapping)) {
    stop("Invalid then_col: ", then_col)
  }
  
  # Helper function for quoting values
  quote_value <- function(val, qtype) {
    if (is.numeric(val) && qtype == "auto") {
      return(as.character(val))
    }
    
    val_str <- as.character(val)
    if (qtype == "single") {
      escaped <- gsub("'", "''", val_str)
      return(paste0("'", escaped, "'"))
    } else if (qtype == "double") {
      escaped <- gsub('"', '""', val_str)
      return(paste0('"', escaped, '"'))
    } else { # auto
      return(paste0("'", gsub("'", "''", val_str), "'"))
    }
  }
  
  statement <- "\nCASE"
  for (i in 1:nrow(mapping)){
    when_val <- mapping[i, when_idx]
    then_val <- mapping[i, then_idx]
    
    # Handle NA values based on handle_nulls parameter
    if (is.na(when_val) || is.na(then_val)) {
      if (handle_nulls == "error") {
        stop("NA values found in row ", i, ". Set handle_nulls='skip' to ignore or 'null' to use NULL.")
      } else if (handle_nulls == "skip") {
        warning("Skipping row ", i, " due to NA values.")
        next
      } else if (handle_nulls == "null") {
        when_val <- if (is.na(when_val)) "NULL" else when_val
        then_val <- if (is.na(then_val)) "NULL" else then_val
      }
    }
    
    when_quoted <- if (is.na(when_val) && handle_nulls == "null") "NULL" else quote_value(when_val, quote_type)
    then_quoted <- if (is.na(then_val) && handle_nulls == "null") "NULL" else quote_value(then_val, quote_type)
    
    statement = paste(statement, " WHEN ", when_quoted, " THEN ", then_quoted, "\n", sep="")
  }
  
  # Add ELSE clause if specified
  if (!is.null(else_value)) {
    else_quoted <- quote_value(else_value, quote_type)
    statement <- paste(statement, " ELSE ", else_quoted, "\n", sep="")
  }
  
  cat(statement)
  return(statement)
}

