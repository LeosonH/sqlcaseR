#' Generate a SQL IN statement from a mapping file
#'
#' This function constructs an IN statement from a mapping file or
#' dataframe. By default it uses the first column, but you can specify
#' a different column by name or index.
#'
#' @param inputfile Dataframe OR path to the mapping file
#' @param header If reading a csv file, TRUE if the file includes a header row,
#' FALSE if it does not include a header row.
#' @param value_col Column name or index for IN values (default: 1)
#' @param quote_type Type of quotes to use: "single", "double", or "auto" (default: "single")
#' @param handle_nulls How to handle NULL/NA values: "skip", "null", or "error" (default: "skip")
#' @param distinct Remove duplicate values if TRUE (default: TRUE)
#' @return A string that represents the constructed IN statement
#' @export
#' @examples 
#'  input <- data.frame(Training = c("Strength", "Stamina", "Other"))
#'  result <- inlist(inputfile = input, value_col = "Training")
inlist <- function(inputfile = NULL, header = FALSE, value_col = 1, 
                   quote_type = "single", handle_nulls = "skip", distinct = TRUE){
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
  
  if (!is.logical(distinct)) {
    stop("distinct must be TRUE or FALSE")
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
  
  if (ncol(mapping) < 1) {
    stop("Input data must have at least 1 column for IN values.")
  }
  
  # Resolve column reference
  value_idx <- if (is.character(value_col)) {
    which(colnames(mapping) == value_col)
  } else {
    value_col
  }
  
  if (length(value_idx) == 0 || value_idx < 1 || value_idx > ncol(mapping)) {
    stop("Invalid value_col: ", value_col)
  }
  
  # Extract values from specified column
  all_values <- mapping[, value_idx]
  
  # Handle NA values
  if (any(is.na(all_values))) {
    if (handle_nulls == "error") {
      stop("NA values found in data. Set handle_nulls='skip' to ignore or 'null' to include NULL.")
    } else if (handle_nulls == "skip") {
      valid_values <- all_values[!is.na(all_values)]
      if (length(valid_values) < length(all_values)) {
        warning("Removed ", length(all_values) - length(valid_values), " NA values.")
      }
    } else if (handle_nulls == "null") {
      valid_values <- all_values  # Keep NAs, will handle in quoting
    }
  } else {
    valid_values <- all_values
  }
  
  if (length(valid_values) == 0) {
    stop("No valid values found after processing.")
  }
  
  # Remove duplicates if requested
  if (distinct) {
    original_length <- length(valid_values)
    valid_values <- unique(valid_values)
    if (length(valid_values) < original_length) {
      message("Removed ", original_length - length(valid_values), " duplicate values.")
    }
  }
  
  # Helper function for quoting values
  quote_value <- function(val, qtype) {
    if (is.na(val) && handle_nulls == "null") {
      return("NULL")
    }
    
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
  
  # Build the IN statement
  quoted_values <- sapply(valid_values, function(x) quote_value(x, quote_type))
  statement <- paste("\nIN(", quoted_values[1], sep = "")
  
  if (length(quoted_values) > 1) {
    for (i in 2:length(quoted_values)){
      statement <- paste(statement, ", ", quoted_values[i], sep="")
    }
  }
  statement <- paste(statement, ")\n", sep="")
  cat(statement)
  cat("\n")
  return(statement)
}

