# The SHY (SHarpe Yield) strategy for long term investment

require(ggplot2)

if (!exists('UTIL_R')) {
  source('util.R')
}

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
  if (class(data) != 'data.frame') {
    stopifnot(is.na(data))
    return (NULL)
  }

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

get_yields <- function(csv_file, cared_date=NA, data=data.frame())
{
  stopifnot(class(data) == 'data.frame')
  csv_data = if (0 == length(data)) get_csv_data(csv_file, cared_date) else data
  pruned_data = get_pruned_data_by_yield(csv_data)
  if (FALSE == pass_criteria(pruned_data)) {
    return (NA)
  }
  return (pruned_data[, YIELD])
}

get_shy_adjust_factor <- function(yields)
{
  return (sqrt(length(yields)))
}

get_shy_values <- function(csv_file, cared_date=NA, data=data.frame())
{
  yields = get_yields(csv_file, cared_date, data)
  if ('logical' == class(yields)) {
    stopifnot(is.na(yields))
    return (data.frame(shy=NA, adjust_factor=NA))
  }
  # we don't expect a higher shy value caused by a yield-sd lower than 1
  adopted_sd = if (sd(yields) > 1) sd(yields) else 1
  shy = mean(yields) / adopted_sd
  return (data.frame(shy=shy, adjust_factor=get_shy_adjust_factor(yields)))
}

get_shy <- function(csv_file, cared_date=NA, data=data.frame())
{
  shy_values = get_shy_values(csv_file, cared_date, data)
  return (shy_values$shy)
}

dump <- function(row_values, more_info)
{
  idx = row_values[1]
  id = row_values[2]
  dump_str = c("(", idx, ") 個股：", id, ", ＳＨＹ：", row_values[3])
  if (more_info) {
    more_dump_str = c(", 調整值：", row_values[4])
    dump_str = c(dump_str, more_dump_str)
  }
  print(paste(dump_str, collapse=''))
}

get_shy_suggestion <- function(cared_date=NA, more_info=FALSE, silence=FALSE, in_csv_files=NA)
{
  COMPUTE_LIMIT = -1  # -1 means no limit
  csv_root = paste0(getwd(), '/', CSV_HOME)  # paste(..., sep='')
  csv_files = if (class(in_csv_files) == 'logical' && is.na(in_csv_files))
    Sys.glob(paste0(csv_root, "*.csv")) else in_csv_files

  csv_cnt = if (-1 != COMPUTE_LIMIT & length(csv_files) > COMPUTE_LIMIT) COMPUTE_LIMIT else length(csv_files)
  shy_values = data.frame(matrix(nrow=csv_cnt, ncol=2))  # 2 for 'shy', 'adjust_factor'
  colnames(shy_values) = c('shy', 'adjust_factor')
  for (i in 1:csv_cnt) {
    ret_values = get_shy_values(csv_files[i], cared_date)
    shy_values$shy[i] = ret_values$shy
    shy_values$adjust_factor[i] = ret_values$adjust_factor
  }
  id_list = gsub(".csv", "", gsub(csv_root, "", csv_files))[1:csv_cnt]
  shy_frame = data.frame(id=id_list, shy=shy_values$shy, adjust_factor=shy_values$adjust_factor)
  ordered_frame = shy_frame[order(shy_frame$shy * shy_frame$adjust_factor, decreasing=TRUE),]
  indexed_frame = cbind(idx=1:csv_cnt, ordered_frame)  # add index column

  if (FALSE == silence)
  {
    #print("推薦個股（依評比由高至低）如下：")
    suggest_cnt = if (csv_cnt > SUGGEST_CNT) SUGGEST_CNT else csv_cnt
    apply(indexed_frame[1:suggest_cnt,], 1, dump, more_info=more_info)  # '1' indicates rows
  }

  return (ordered_frame)
}

library(ggplot2)

show_yield_points <- function()
{
  COMPUTE_LIMIT = -1  # -1 means no limit
  
  csv_root = paste0(getwd(), '/', CSV_HOME)  # paste(..., sep='')
  csv_files = Sys.glob(paste0(csv_root, "*.csv"))
  csv_cnt = if (-1 != COMPUTE_LIMIT & length(csv_files) > COMPUTE_LIMIT) COMPUTE_LIMIT else length(csv_files)
  mean_values = double(csv_cnt)
  sd_values = double(csv_cnt)
  for (i in 1:csv_cnt) {
    yields = get_yields(csv_files[i])
    mean_values[i] = mean(yields)
    sd_values[i] = sd(yields)
  }
  
  id_list = gsub(".csv", "", gsub(csv_root, "", csv_files))[1:csv_cnt]
  yield_frame = data.frame(id=id_list, mean=mean_values, sd=sd_values)
  sd_values[sd_values < 1] <- 1  # Note: in-place modification, for we do not expect a larger shy value by a less than 1 sd-yield
  shy_values = mean_values / sd_values
  max_shy = max(shy_values, na.rm=TRUE)
  min_shy = min(shy_values, na.rm=TRUE)
  # for shy distribution may be 'normal', and thus to have a more even 'red-green' proportion,
  # we intend to larger the 'red range' by sqrt operation
  red_values = sqrt((shy_values - min_shy) / (max_shy - min_shy))
  green_values = 1 - (red_values)
  colors = character(csv_cnt)
  for (i in 1:csv_cnt)
  {
    is_na = is.na(red_values[i])
    colors[i] = rgb(red=if (is_na) 1 else red_values[i],
                    green=if (is_na) 1 else green_values[i], 
                    blue=if (is_na) 1 else 0)
  }
  
  p = ggplot(yield_frame, aes(x=mean, y=sd, label=id)) + 
    ggtitle(if (ENG == LANG) 'Concept of SHY' else 'SHY概念示意圖') +
            xlab(if (ENG == LANG) 'Yield (AVG)' else '殖利率（平均值）') +
            ylab(if (ENG == LANG) 'Yield (STDEV)' else '殖利率（標準差）') +
    theme(text=element_text(family='STKaiti')) + # to support Chinese characters
    geom_text(size=3, hjust=0, nudge_x=0.02, color=colors, na.rm=TRUE) +
    scale_x_continuous(trans='sqrt') +
    scale_y_continuous(trans='log2') +
    #scale_y_reverse() + # sd (y-axis) is shown reversed
    geom_point(color=colors, na.rm=TRUE, size=0.5)
  print(p)
  
  return (yield_frame)
}
