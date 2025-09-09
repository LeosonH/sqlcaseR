#' Generate a SQL UPDATE statement from a mapping file
#'
#' This function constructs UPDATE statements from a mapping file or
#' dataframe. By default, it uses the first column as the key column for WHERE clauses,
#' and updates all other columns. You can specify which columns to use.
#'
#' @param inputfile Dataframe OR path to the mapping file  
#' @param tablename Name of the SQL table
#' @param key_col Column name or index for WHERE clause key (default: 1)
#' @param update_cols Vector of column names/indices to update (default: all except key_col)
#' @param quote_type Type of quotes to use: "single", "double", or "auto" (default: "auto")
#' @param handle_nulls How to handle NULL/NA values: "skip", "null", or "error" (default: "skip")
#' @param batch_updates If TRUE, create one UPDATE per row; if FALSE, create one per column (default: TRUE)
#' @return A string that represents the constructed UPDATE statement(s)
#' @export
#' @examples 
#'  input <- data.frame(id = c(1, 2, 3), name = c("John", "Jane", "Bob"), 
#'                      age = c(25, 30, 35))
#'  result <- updatetable(input, "users", key_col = "id", update_cols = c("name", "age"))
updatetable <- function(inputfile = NULL, tablename = NULL, key_col = 1, update_cols = NULL,
                        quote_type = "auto", handle_nulls = "skip", batch_updates = TRUE){
  if (is.null(inputfile) == TRUE) {
    stop("Please include a file path or an input dataframe.")
  }
  if (is.null(tablename) == TRUE) {
    stop("Please include the name for the SQL table to be updated.")
  }
  
  # Validate parameters
  if (!is.character(tablename) || nchar(trimws(tablename)) == 0) {
    stop("Table name must be a non-empty character string.")
  }
  
  if (!quote_type %in% c("single", "double", "auto")) {
    stop("quote_type must be one of: 'single', 'double', 'auto'")
  }
  
  if (!handle_nulls %in% c("skip", "null", "error")) {
    stop("handle_nulls must be one of: 'skip', 'null', 'error'")
  }
  
  if (!is.logical(batch_updates)) {
    stop("batch_updates must be TRUE or FALSE")
  }
  
  if (is.character(inputfile)) {
    if (!file.exists(inputfile)) {
      stop("File does not exist: ", inputfile)
    }
    tryCatch({
      mapping <- utils::read.csv(inputfile, header = TRUE)
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
    stop("Input data must have at least 2 columns (key column and at least one update column).")
  }
  
  columns <- colnames(mapping)
  if (any(is.na(columns)) || any(nchar(trimws(columns)) == 0)) {
    stop("All columns must have valid names.")
  }
  
  # Resolve key column reference
  key_idx <- if (is.character(key_col)) {
    which(colnames(mapping) == key_col)
  } else {
    key_col
  }
  
  if (length(key_idx) == 0 || key_idx < 1 || key_idx > ncol(mapping)) {
    stop("Invalid key_col: ", key_col)
  }
  
  # Resolve update columns
  if (is.null(update_cols)) {
    update_indices <- setdiff(1:ncol(mapping), key_idx)  # All columns except key
  } else {
    if (is.character(update_cols)) {
      update_indices <- which(colnames(mapping) %in% update_cols)
    } else {
      update_indices <- update_cols
    }
    
    if (length(update_indices) == 0 || any(update_indices < 1) || any(update_indices > ncol(mapping))) {
      stop("Invalid update_cols: ", paste(update_cols, collapse = ", "))
    }
  }
  
  if (key_idx %in% update_indices) {
    stop("Key column cannot be in update columns")
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
      if (is.numeric(val)) {
        return(as.character(val))
      } else {
        return(paste0("'", gsub("'", "''", val_str), "'"))
      }
    }
  }
  
  statement <- ""
  for (i in 1:nrow(mapping)){
    key_val <- mapping[i, key_idx]
    
    # Handle NA key values
    if (is.na(key_val)) {
      if (handle_nulls == "error") {
        stop("NA key value found in row ", i, ".")
      } else {
        warning("Skipping row ", i, " due to NA key value.")
        next
      }
    }
    
    statement <- paste(statement, "\nUPDATE ", tablename, "\nSET ", sep = "")
    
    has_updates <- FALSE
    update_clauses <- c()
    
    for (j in update_indices){
      update_val <- mapping[i, j]
      
      # Handle NA update values
      if (is.na(update_val)) {
        if (handle_nulls == "error") {
          stop("NA update value found in row ", i, ", column ", columns[j], ".")
        } else if (handle_nulls == "skip") {
          next  # Skip this column
        } else if (handle_nulls == "null") {
          # Will be handled in quote_value
        }
      }
      
      has_updates <- TRUE
      quoted_val <- quote_value(update_val, quote_type)
      update_clauses <- c(update_clauses, paste(columns[j], " = ", quoted_val, sep=""))
    }
    
    if (!has_updates) {
      warning("Skipping row ", i, " - no valid update values found.")
      next
    }
    
    # Join update clauses
    statement <- paste(statement, paste(update_clauses, collapse = ", "), sep="")
    
    # Add WHERE clause
    key_quoted <- quote_value(key_val, quote_type)
    statement <- paste(statement, "\nWHERE ", columns[key_idx], " = ", key_quoted, ";\n", sep = "")
  }
  
  if (nchar(trimws(statement)) == 0) {
    warning("No valid UPDATE statements generated.")
    return("")
  }
  
  statement <- paste(statement, "\n", sep="")
  cat(statement)
  cat("\n")
  return(statement)
}