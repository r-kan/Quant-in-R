# Common utility functions

UTIL_R = 0

source("setting.R")
source("value_type.R")

if (!exists("DEBUG", mode="numeric"))
  DEBUG = 0

FINISH_EVAL_DATE = Sys.Date() # that means 'today'
MAX_YIELD_BOUND = 99999
SUGGEST_CNT = 30

dprint <- function(msg)
{
  if (DEBUG) {
    print(msg)
  }
}

to_date <- function(date_str)
{
  return (unclass(as.Date(strptime(date_str, "%Y/%m/%d"))))
}

# cared_date shall be 'Date' class, e.g., as.Date('2016-11-16')
get_cared_index <- function(date_values, cared_date)
{
  stopifnot(class(cared_date) == 'Date')
  for (i in 1:length(date_values))
  {
    iter_date = as.Date(strptime(date_values[i], "%Y/%m/%d"))
    if (cared_date > iter_date) {  # we expect the date_values is from newest to oldest
      break
    }
    if (cared_date == iter_date) {
      return (i)
    }
  }
  return (NA)
}

# The CachedCsvData serialization --- begin
CachedCsvData = new.env()  # use environment as a hash table
CachedCsvData$sig <- list()

clear_cached_csv_data <- function() { rm(list=names(CachedCsvData), envir=CachedCsvData) }

get_cached_csv_data <- function(signature)
{
  stopifnot(class(signature) == 'character')
  entry = CachedCsvData[[signature]]
  if (is.null(entry)) {
    return (NULL)
  }
  return (entry)
}

# each entry size can be shown by 'object.size()'
# suppose average entry size is 0.5MB, and we want limit total cache memory size under 200MB,
# then cache entry size can up to 200/0.5 = 400 => when size larger than 400, we need clear entries by FIFO manner
# TODO: consider using LRU
MAX_CACHED_ENTRY_SIZE = 400

update_cached_csv_data <- function(signature, values)
{
  stopifnot(class(signature) == 'character')
  stopifnot(is.null(CachedCsvData[[signature]]))
  CachedCsvData[[signature]] = values
  if (grepl('0050', signature)) { return (NULL) } # do not consider remove cache entry if it is 0050
  
  CachedCsvData$sig[[length(CachedCsvData$sig) + 1]] <- signature
  if (length(CachedCsvData$sig) > MAX_CACHED_ENTRY_SIZE) {
    first_entry = CachedCsvData$sig[[1]]
    rm(list=first_entry, envir=CachedCsvData)
    CachedCsvData$sig[[1]] = NULL
  }
}

# The CachedCsvData serialization --- end

# cared_date: the newest date csv_data shall contain
# cared_date_start: the oldest date csv_data shall contain
get_csv_data <- function(csv_file, cared_date=NA, cared_value=c(YIELD, DATE, CLOSE, VOLUME, ADJCLOSE), cared_date_start=NA)
{
  #clear_cached_csv_data()
  "signature = paste0(csv_file, cared_date, paste(cared_value, collapse=''), cared_date_start)
  cached_csv_data = get_cached_csv_data(signature)
  if (class(cached_csv_data) != 'NULL') {
    return (cached_csv_data)
  }"

  dprint(paste("[util] 讀取", csv_file)) # default sep is ' '

  # the string in vector must be in same order in integer value definition, or later 'yield == na_cols[i]' will be
  # wrong (no good...)
  column_names = cared_value
  csv_data = read.csv(csv_file, na.strings=c("NA", "NULL"))  # read.csv returns 'data.frame'
  stock_values = csv_data[, column_names]
  stopifnot(is.na(cared_date) | is.na(cared_date_start))  # just not support both are non-NA now
  if (FALSE == is.na(cared_date)) {
    cared_idx = get_cared_index(as.vector(stock_values$date), cared_date)
    if (is.na(cared_idx)) {
      #update_cached_csv_data(signature, NA)
      return (NA)
    }
    stock_values = stock_values[cared_idx:nrow(stock_values),]
  }
  if (Sys.Date() != FINISH_EVAL_DATE) {  # Note: Sys.Date() = today
    #stopifnot(FALSE)
    cared_idx = get_cared_index(as.vector(stock_values$date), FINISH_EVAL_DATE)
    stock_values = if (is.na(cared_idx)) stock_values else stock_values[cared_idx:nrow(stock_values),]
  }
  if (FALSE == is.na(cared_date_start)) {
    cared_idx = get_cared_index(as.vector(stock_values$date), cared_date_start)
    stock_values = if (is.na(cared_idx)) stock_values else stock_values[1:cared_idx,]
  }
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
    { 
      dprint(paste("排除上一個殖利率為ＮＡ出現之前的日期", stock_values[, DATE][na_rows[last_na_yield_row]]))
      # remove the rows with non-yield NA value
      stock_values <- stock_values[-c(na_rows[1:last_na_yield_row - 1]),]
      # remove all rows after date of last NA yield ('- unique_na_row_cnt' bcoz non-yield NA rows is just removed)
      unique_na_row_cnt = length(unique(c(na_rows[1:last_na_yield_row - 1])))
      ret = stock_values[1:(na_rows[last_na_yield_row] - unique_na_row_cnt - 1),]
      #update_cached_csv_data(signature, ret)
      return (ret)
    }
    #update_cached_csv_data(signature, stock_values[-c(na_rows),])
    return (stock_values[-c(na_rows),])  # remove all row with NA value (no yield is NA)
  }
  #update_cached_csv_data(signature, stock_values)
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
  
  return (id_list)
}

STOCK_NAME_FILE = 'stock_name.list'

get_stock_name <- function(stock_id)
{
  stock_names = read.csv(STOCK_NAME_FILE)
  for (i in 1:nrow(stock_names))
  {
    if (stock_names$id[i] == stock_id) {
      return (as.character(stock_names$name[i]))
    }
  }
  return (stock_id)
}
