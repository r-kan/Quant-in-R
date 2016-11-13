# Common utility functions

source("value_type.R")

if (!exists("DEBUG", mode="numeric"))
  DEBUG = 0

MAX_YIELD_BOUND = 99999
CSV_HOME = "csv/"
SUGGEST_CNT = 30

dprint <- function(msg)
{
  if (DEBUG) {
    print(msg)
  }
}

get_csv_data <- function(csv_file)
{
  dprint(paste("讀取", csv_file)) # default sep is ' '

  # the string in vector must be in same order in integer value definition, or later 'yield == na_cols[i]' will be
  # wrong (no good...)
  column_names = c(YIELD, DATE, CLOSE, VOLUME)
  csv_data = read.csv(csv_file, na.strings=c("NA", "NULL"))  # read.csv returns 'data.frame'
  stock_values = csv_data[, column_names]
  # 1. 'which' returns indices with TRUE value, 2. colnames(na_indices) = "row" "col"
  na_indices = as.data.frame(which(is.na(stock_values), arr.ind=TRUE))
  na_indices = na_indices[order(na_indices$row),]  # order na_indices from newest to oldest date (less row idx is newer)
  na_rows = na_indices$row
  na_cols = na_indices$col
  last_na_yield_row = 1
  if (nrow(na_indices) > 0)
  {
    # Note: the folloiwng 'NA/NULL-eliminated' principle might not be valid for some value type...
    for (i in 1:nrow(na_indices))
    {
      if (yield == na_cols[i]) {
        last_na_yield_row = i
        break
      }
      dprint(paste("移除未有交易資料的日期", stock_values[, DATE][na_rows[i]]))  # remove action at below if or return stmt
    }
    if (last_na_yield_row > 1)
    { # remove the rows with non-yield NA value
      stock_values <- stock_values[-c(na_rows[1:last_na_yield_row - 1]),]
      dprint(paste("排除上一個殖利率為ＮＡ出現之前的日期", stock_values[, DATE][na_rows[last_na_yield_row]]))
      # remove all rows after date of last NA yield ('-' bcoz non-yield NA rows is just removed)
      return (stock_values[1:(na_rows[last_na_yield_row] - last_na_yield_row),])
    }
    return (stock_values[-c(na_rows),])  # remove all row with NA value (no yield is NA)
  }

  return (stock_values)
}

get_csv_file <- function(id)
{
  return (paste0(getwd(), '/', CSV_HOME, id, ".csv"))
}

get_aval_stock_list <- function()
{
  csv_root = paste0(getwd(), '/', CSV_HOME)  # paste(..., sep='')
  csv_files = Sys.glob(paste0(csv_root, "*.csv"))
  id_list <- gsub(".csv", "", gsub(csv_root, "", csv_files))
}
