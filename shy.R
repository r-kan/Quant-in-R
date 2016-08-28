# A long term investment strategy: SHY (SHarpe Yield)
#   input: a directory with stock csv files, e.g., 2330.csv
#   output: the stock id list, from most to least suggested target

get_cared_data <- function(csv_file, column_names)
{
  print(paste("讀取", csv_file)) # default sep is ' '

  csv_data = read.csv(csv_file)
  column_values = csv_data[, column_names]
  na_indexes = which(is.na(column_values), arr.ind=TRUE)
  stopifnot(0 == na_indexes)

  return (column_values) 
}

# TODO: support customized filtering rule using 'date, 'close', and 'volume'
pass_criteria <- function(data)
{
  return (TRUE)
}

# prune the input data to only keep values with date from 1st positive yield
get_pruned_data_by_yield <- function(data)
{
  yields = data[, "yield"]
  
  start_positive_index = -1
  for (i in length(yields):1)
  {
    if (yields[i] > 0) {
      start_positive_index = i
      if (start_positive_index != length(yields)) {
        print(paste("只考慮正殖利率開始的日期", data[, "date"][start_positive_index]))
        return (data[1:start_positive_index,])  # rows: 1-start_positive_index, columns: keep all
      }
      break
    }
  }
  
  return (data)
}

get_shy <- function(id)
{
  cared_data = get_cared_data(id, c("yield", "date", "close", "volume"))
  pruned_data = get_pruned_data_by_yield(cared_data)
  if (!pass_criteria(pruned_data)) {
    return (-1)
  }

  yields = pruned_data[, "yield"]
  shy = mean(yields) / sd(yields)

  return (shy)
}

dump <- function(row_values)
{
  id = paste("個股：", row_values[1])
  shy = paste(", 夏普殖利率：", row_values[2])
  print(paste(id, shy, sep=''))
}

get_shy_suggestion <- function(csv_root = paste(getwd(), "/csv_dump/", sep=''))
{
  csv_limit = 5
  suggest_cnt = 3
  
  pattern = paste(c(csv_root, "*.csv"), collapse = '')
  csv_files <- Sys.glob(pattern)
  csv_cnt = if (length(csv_files) > csv_limit) csv_limit else length(csv_files)
  id_list <- gsub(".csv", "", gsub(csv_root, "", csv_files))[1:csv_cnt]
  shy_list <- double(csv_cnt)
  for (i in 1:csv_cnt) {
    shy_list[i] = get_shy(csv_files[i])
  }
  
  shy_frame = data.frame(id=id_list, shy=shy_list)
  ordered_frame = shy_frame[order(shy_frame$shy, decreasing=TRUE),]
  
  report_cnt = if (csv_cnt > suggest_cnt) suggest_cnt else csv_cnt
  print("推薦個股（依評比由高至低）如下：")
  apply(ordered_frame[1:report_cnt,], 1, dump)

  return (ordered_frame)
}

suggestion = get_shy_suggestion()

