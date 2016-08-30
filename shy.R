# The long term investment strategy: SHY (SHarpe Yield)

get_cared_data <- function(csv_file, column_names)
{
  print(paste("讀取", csv_file)) # default sep is ' '

  csv_data = read.csv(csv_file)
  column_values = csv_data[, column_names]
  null_indexes = which(is.null(column_values), arr.ind=TRUE)
  stopifnot(0 == null_indexes)
  na_indexes = which(is.na(column_values), arr.ind=TRUE)
  if (length(na_indexes) > 0 & na_indexes[1] > 0) {
    # Note: the folloiwng 'NA-eliminated' principle might not be valid for some value type...
    print(paste("排除最後一個ＮＡ出現之前的日期", csv_data[, "date"][na_indexes[1]]))
    return (column_values[1:na_indexes[1] - 1,])
  }

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

get_shy <- function(csv_file, data=list())
{
  cared_data = if (0 == length(data)) get_cared_data(csv_file, c("yield", "date", "close", "volume")) else data
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
  print(paste(c("個股：", row_values[1], ", 夏普殖利率：", row_values[2]), collapse=''))
}

get_shy_suggestion <- function(csv_root = paste(getwd(), "/csv/", sep=''))
{
  csv_limit = 50
  suggest_cnt = 5
  
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

  return (as.vector(ordered_frame[, "id"]))
}
