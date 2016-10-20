# The long term investment strategy: SHY (SHarpe Yield)

source("value_type.R")
source("util.R")
#DEBUG=1

get_csv_data <- function(csv_file)
{
  dprint(paste("讀取", csv_file)) # default sep is ' '

  column_names = c(vname(yield), vname(date), vname(close), vname(volume))  # TODO: remove order dependency
  csv_data = read.csv(csv_file, na.strings=c("NA", "NULL"))
  column_values = csv_data[, column_names]
  na_indexes = as.data.frame(which(is.na(column_values), arr.ind=TRUE))
  na_indexes = na_indexes[order(na_indexes$row),]
  start_na_yield_row = 1
  if (nrow(na_indexes) > 0)
  {
    # Note: the folloiwng 'NA/NULL-eliminated' principle might not be valid for some value type...
    for (i in 1:nrow(na_indexes))
    {
      if (yield == na_indexes$col[i]) {
        start_na_yield_row = i
        break
      }
      dprint(paste("移除未有交易資料的日期", csv_data[, "date"][na_indexes$row[i]]))
    }
    if (start_na_yield_row > 1) 
    {  # remove the rows with non-yield NA value(s)
      column_values <- column_values[-c(na_indexes$row[1:start_na_yield_row - 1]),]
      dprint(paste("排除最後一個ＮＡ出現之前的日期", csv_data[, "date"][na_indexes$row[start_na_yield_row]]))
      return (column_values[1:(na_indexes$row[start_na_yield_row] - start_na_yield_row),])
    }
    return (column_values[-c(na_indexes$row),])
  }

  return (column_values) 
}

pass_criteria <- function(data)
{
  if (is.null(data)) { return (FALSE) }
  
  required_existed_day_count = 750  # 250 days * 3 => 1 year * 3
  if (nrow(data) < required_existed_day_count) {
    dprint("個股連續有交易資料期間未滿三年，不予考慮")
    return (FALSE)
  }
  
  required_volume_mean = -1  # Note: the volume unit of csv raw data is 1,000,000 NTD
  if (-1 != required_volume_mean & mean(data$volume) < required_volume_mean) {
    dprint(paste("個股平均成交量未達標準，不予考慮：", mean(data$volume)))
    return (FALSE)
  }
  
  return (TRUE)
}

# prune the input data to only keep values with date from 1st positive yield
get_pruned_data_by_yield <- function(data)
{
  yields = data[, "yield"]

  if (0 == length(yields) | is.na(yields[1])) {
    dprint("個股無最近日期資料")
    return (NULL)
  }
  
  start_negative_index = -1
  for (i in 1:length(yields))
  {
    if (yields[i] <= 0) {
      if (0 == i) {
        dprint("個股最近無正殖利率")
        return (NULL)
      }
      start_negative_index = i
      dprint(paste("只考慮從上一次正殖利率開始的日期", data[, "date"][start_negative_index - 1]))
      return (data[1:start_negative_index - 1,])  # rows: start_negative_index - 1, columns: keep all
    }
  }
  
  return (data)
}

get_shy <- function(csv_file, data=list())
{
  csv_data = if (0 == length(data)) get_csv_data(csv_file) else data
  pruned_data = get_pruned_data_by_yield(csv_data)
  if (!pass_criteria(pruned_data)) {
    return (NA)
  }

  yields = pruned_data[, "yield"]
  # we don't expect a higher shy value caused by a yield-sd lower than 1
  adopted_sd = if (sd(yields) > 1) sd(yields) else 1
  shy = mean(yields) / adopted_sd

  return (shy)
}

get_csv_file <- function(id)
{
  return (paste(c(getwd(), '/', CSV_HOME, id, ".csv"), collapse=''))
}

# Note: it is not a good name for 'other_stock_values', however, shall be acceptable if we only use
#       it to retrieve two other values (when more than three values, then better refactor it)
get_other_stock_values <- function(id)
{
  csv_file = get_csv_file(id)
  csv_data = get_csv_data(csv_file)
  pruned_data = get_pruned_data_by_yield(csv_data)
  
  valid_yield_cnt = nrow(pruned_data)
  current_close = pruned_data[1, "close"]
  return (c(valid_yield_cnt, current_close))
}

dump <- function(row_values, more_info)
{
  id = row_values[1]
  stock_values = get_other_stock_values(id)
  dump_str = c("個股：", id, ", 夏普殖利率：", row_values[2])
  if (more_info) {
    more_dump_str = c(", 天數：", stock_values[1], ", 收盤價：", stock_values[2])
    dump_str = c(dump_str, more_dump_str)
  }
  print(paste(dump_str, collapse=''))
}

get_shy_suggestion <- function(more_info=FALSE)
{
  csv_limit = -1  # -1 means no limit
  suggest_cnt = 30
  
  csv_root = paste(getwd(), '/', CSV_HOME, sep='')
  pattern = paste(c(csv_root, "*.csv"), collapse = '')
  csv_files <- Sys.glob(pattern)
  csv_cnt = if (-1 != csv_limit & length(csv_files) > csv_limit) csv_limit else length(csv_files)
  id_list <- gsub(".csv", "", gsub(csv_root, "", csv_files))[1:csv_cnt]
  shy_list <- double(csv_cnt)
  for (i in 1:csv_cnt) {
    shy_list[i] = get_shy(csv_files[i])
  }
  
  shy_frame = data.frame(id=id_list, shy=shy_list)
  ordered_frame = shy_frame[order(shy_frame$shy, decreasing=TRUE),]
  
  report_cnt = if (csv_cnt > suggest_cnt) suggest_cnt else csv_cnt
  print("推薦個股（依評比由高至低）如下：")
  apply(ordered_frame[1:report_cnt,], 1, dump, more_info=more_info)

  return (as.vector(ordered_frame[, "id"]))
}
