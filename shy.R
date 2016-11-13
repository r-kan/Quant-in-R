# The SHY (SHarpe Yield) strategy for long term investment

source("util.R")

pass_criteria <- function(data)
{
  if (is.null(data)) { return (FALSE) }
  
  REQUIRED_DAY_COUNT = 750  # 250 days * 3 => 1 year * 3
  if (nrow(data) < REQUIRED_DAY_COUNT) {
    dprint("個股連續有正殖利率期間未滿三年，不予考慮")
    return (FALSE)
  }
  
  REQUIRED_VOLUME_MEAN = -1  # Note: the volume unit of csv raw data is 1,000,000 NTD
  if (-1 != REQUIRED_VOLUME_MEAN & mean(data$volume) < REQUIRED_VOLUME_MEAN) {
    dprint(paste("個股平均成交量未達標準，不予考慮：", mean(data$volume)))
    return (FALSE)
  }
  
  return (TRUE)
}

# prune the input data to only keep values with date from 1st positive yield
get_pruned_data_by_yield <- function(data)
{
  yields = data[, YIELD]

  if (0 == length(yields) | is.na(yields[1])) {
    dprint("個股無最近日期殖利率資料")
    return (NULL)
  }
  
  last_zero_yield_idx = -1
  for (i in 1:length(yields))
  {
    stopifnot(yields[i] >= 0)
    if (0 == yields[i]) {
      if (0 == i) {
        dprint("個股最近日期殖利率為0")
        return (NULL)
      }
      last_zero_yield_idx = i
      dprint(paste("只考慮從上一次正殖利率開始的日期", data[, DATE][last_zero_yield_idx - 1]))
      return (data[1:last_zero_yield_idx - 1,])  # rows: last_zero_yield_idx - 1, columns: keep all
    }
  }
  
  return (data)
}

get_shy <- function(csv_file, data=list())
{
  csv_data = if (0 == length(data)) get_csv_data(csv_file) else data
  pruned_data = get_pruned_data_by_yield(csv_data)
  if (FALSE == pass_criteria(pruned_data)) {
    return (NA)
  }

  yields = pruned_data[, YIELD]
  # we don't expect a higher shy value caused by a yield-sd lower than 1
  adopted_sd = if (sd(yields) > 1) sd(yields) else 1
  shy = mean(yields) / adopted_sd

  return (shy)
}

# Note:
#   'other_stock_values' is no good name, however, may be acceptable if we only use
#   it to retrieve 'two' other values (when more than three, then better have more explicit name)
get_other_stock_values <- function(id)
{
  csv_data = get_csv_data(get_csv_file(id))
  pruned_data = get_pruned_data_by_yield(csv_data)
  
  valid_yield_cnt = nrow(pruned_data)
  last_close = pruned_data[1, CLOSE]
  return (c(valid_yield_cnt, last_close))
}

dump <- function(row_values, more_info)
{
  idx = row_values[1]
  id = row_values[2]
  dump_str = c("(", idx, ") 個股：", id, ", 夏普殖利率：", row_values[3])
  if (more_info) {
    stock_values = get_other_stock_values(id)
    more_dump_str = c(", 天數：", stock_values[1], ", 收盤價：", stock_values[2])
    dump_str = c(dump_str, more_dump_str)
  }
  print(paste(dump_str, collapse=''))
}

get_shy_suggestion <- function(more_info=FALSE)
{
  COMPUTE_LIMIT = -1  # -1 means no limit
  
  csv_root = paste0(getwd(), '/', CSV_HOME)  # paste(..., sep='')
  csv_files = Sys.glob(paste0(csv_root, "*.csv"))
  csv_cnt = if (-1 != COMPUTE_LIMIT & length(csv_files) > COMPUTE_LIMIT) COMPUTE_LIMIT else length(csv_files)
  shy_values = double(csv_cnt)  # a double-precision vector
  for (i in 1:csv_cnt) {
    shy_values[i] = get_shy(csv_files[i])
  }

  id_list = gsub(".csv", "", gsub(csv_root, "", csv_files))[1:csv_cnt]
  shy_frame = data.frame(id=id_list, shy=shy_values)
  ordered_frame = shy_frame[order(shy_frame$shy, decreasing=TRUE),]
  indexed_frame = cbind(idx=1:csv_cnt, ordered_frame)  # add index column

  print("推薦個股（依評比由高至低）如下：")
  suggest_cnt = if (csv_cnt > SUGGEST_CNT) SUGGEST_CNT else csv_cnt
  apply(indexed_frame[1:suggest_cnt,], 1, dump, more_info=more_info)  # '1' indicates rows

  return (ordered_frame)
}
