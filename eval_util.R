# Utility routines for evaluation

source('setting.R')
if (!exists('UTIL_R')) {
  source('util.R')
}

# Note: 
#   For 'as.Date', the 'original' verson need 'origin' specified when date input is a integer
#   'zoo' overwrite the original version by providing a default origin
#   In conclusion, it is expected a RStudio start-up, without source file and then loading packages,
#   can have the following error happens
#     "Error in as.Date.numeric(end_date) : 'origin' must be supplied"
#   Or, add "origin='1970-01-01'" for every calling to 'as.Date' (which seems too annoying...)
# ref.: https://stat.ethz.ch/pipermail/r-help/2010-March/233159.html

require(quantmod)  # for 'ROC': rate of change
require(PerformanceAnalytics)

START_EVAL_DATE = as.Date('2005-01-03')

stock_id_closure <- function(id)
{
  function(dummy_input) id
}

get_market_dates <- function(start_date)
{
  stopifnot(class(start_date) == 'Date')
  
  GOLDEN_STOCK_ID = '0050'
  # TODO: only use 'DATE' will cause error in 'get_csv_data'
  csv_data = get_csv_data(get_csv_file(GOLDEN_STOCK_ID), cared_value=c(DATE, CLOSE))
  date_values = as.vector(csv_data$date)
  cvt_dates = list()  # converted (to unclass of 'Date') dates
  for (i in 1:length(date_values))
  {
    iter_date = to_date(date_values[i])
    if (unclass(FINISH_EVAL_DATE) < iter_date) {
      stopifnot(FALSE)
      next
    }
    if (unclass(start_date) > iter_date) {  # we expect the date_values is from newest to oldest
      break
    }
    cvt_dates[[length(cvt_dates) + 1]] = iter_date
  }

  return (rev(cvt_dates))  # reverse to 'oldest to newest' for adopted package (zoo, xts) expects such fashsion
}

get_newest_market_dates <- function()
{
  newest_date = tail(get_market_dates(START_EVAL_DATE), n=1)
  return (gsub('-', '/', as.Date(newest_date[[1]])))
}

# TODO: the 'StockPosDate' related function shall be better to be placed in a class

# The StockPosDate functionality --- begin
# Ref.: http://stackoverflow.com/documentation/r/5179/hashmaps#t=201611191447485497121
StockPosDate = new.env()  # use environment as a hash table

clear_stock_pos_hash <- function()
{
  rm(list=names(StockPosDate), envir=StockPosDate)
}

add_date_entry_into_hash <- function(stock_id, pos_date)
{
  entry = StockPosDate[[stock_id]]
  if (FALSE == is.null(entry)) {
    entry[[length(entry) + 1]] = pos_date
  }
  else {
    entry = list()
    entry[[1]] = pos_date
  }
  
  # TODO: check if this causes a totally overwritten... we actually expect a write on pointer values
  StockPosDate[[stock_id]] = entry
}

get_stocks_from_hash <- function()
{
  return (names(StockPosDate))
}

get_stock_pos_date <- function(stock_id)
{
  entry = StockPosDate[[stock_id]]
  stopifnot(FALSE == is.null(entry))
  return (entry)
}
# The StockPosDate functionality --- end

get_initial_summary <- function(start_date, end_date)
{
  dprint(paste("從", as.Date(start_date), "到", as.Date(end_date)))  # actually, the input 'end_date' is only for print (debug) purpose...
  dates = get_market_dates(as.Date(start_date))
  return (data.frame(date=sapply(dates, unclass), pos_cnt=0, ret_cumu=0, ret_avg=0))
}

add_summary <- function(res_pool, stock_id, buy_dates)
{
  dprint(paste(c('標的：', stock_id, '=> 日期：', sapply(buy_dates, function(x){as.character.Date(as.Date(x))})), collapse = ' '))
  csv_data = get_csv_data(get_csv_file(stock_id), cared_date_start=as.Date(buy_dates[[1]]),
                          cared_value=c(DATE, CLOSE, ADJCLOSE))
  zoo_data = zoo(csv_data[,ADJCLOSE], sapply(csv_data$date, to_date))  # zoo transfers to 'old->new' format, which ROC need
  roc = ROC(zoo_data, type='discrete')
  abnomal_roc_idx = which(sapply(roc, function(x){(is.na(x) | x>0.10 | x< -0.10)}))
  abnomal_roc_idx = abnomal_roc_idx[! abnomal_roc_idx %in% 1] # the 1st entry is always NA for ROC, needless consider it
  if (length(abnomal_roc_idx) > 0) {
    for (i in 1:length(abnomal_roc_idx)) {
      idx = abnomal_roc_idx[i]
      dprint(paste0("忽略ROC=", round(roc[idx], 2), ", 於", as.Date(index(zoo_data)[idx])))
      roc[idx] = 0
    }
  }

  buy_idx = length(buy_dates)
  res_idx = nrow(res_pool)
  buy_date_value = unclass(as.Date(buy_dates[[buy_idx]]))

  for (i in length(zoo_data):3) # i=1: buy decision, i=2: place position => only has returns for '>2'
  { # from newest to oldest
    if (index(zoo_data)[i - 2] < buy_date_value)
    { # Note: 1. zoo keeps unclass Date value as index, 2. as above comment says, there's offset '2' between 'buy' and 'return'
      buy_idx = buy_idx - 1
      if (buy_idx < 1) { break }
      buy_date_value = unclass(as.Date(buy_dates[[buy_idx]]))
    }

    while (res_pool$date[res_idx] != index(zoo_data)[i]) { # stock value (zoo_data) might be loss in certain market dates
      res_idx = res_idx - 1
      stopifnot(res_idx > 0)
    }

    # 1. increment pos_cnt (by buy_idx = cumu. positions of stock_id)
    # 2. add ROC (rate of change) as return in percentage
    res_pool$pos_cnt[res_idx] = res_pool$pos_cnt[res_idx] + buy_idx
    res_pool$ret_cumu[res_idx] = res_pool$ret_cumu[res_idx] + (buy_idx * roc[i])
  }
  
  return (res_pool)
}

get_positions <- function(get_position_func)
{
  # get positions
  dates = get_market_dates(START_EVAL_DATE)  # vector of 'Date', from oldest to newest
  positions = list()
  for (i in seq(1, length(dates), by=EVAL_PERIOD_LEN))  # evaluate from oldest (START_EVAL_DATE) date
  {
    cared_date = as.Date(dates[[i]])
    position = get_position_func(cared_date)
    dprint(paste(c("策略日期：", as.character.Date(cared_date), "=> 標的：", position), collapse = ' '))
    
    pos_with_colname = matrix(position)  # convert to matrix, bcoz later colnames need matrix-like input
    # a work-around (?, maybe not so bad) (put 'date' in colname) until we figure out 
    # how to place data of different type as a whole
    colnames(pos_with_colname) = cared_date
    positions[[length(positions) + 1]] = pos_with_colname
  }
  
  return (positions)
}

# summary format: 
#   observation -> market date, from oldest to newest
#   column -> 
#     pos_cnt: cumulative position count
#     ret_cumu: cumulative return (%)
#     ret_avg: average return (%) <= equals to 'ret_cumu / pos_cnt'
get_evaluate_summary <- function(get_position_func, update_progress=NULL)
{
  positions = get_positions(get_position_func)
  clear_stock_pos_hash()  # reset global data

  if (!is.null(update_progress)) { update_progress(0.0, if (ENG == LANG) 'transfer to stock-oriented data' else '轉換為個股導向資料') }
  # convert to 'stock major' entries from input 'date major' entries (to reduce csv file access)
  for (i in 1:length(positions)) 
  {
    entry = positions[[i]]
    pos_date = as.integer(colnames(entry))
    stocks = as.vector(entry)
    for (i in 1:length(stocks)) {
      add_date_entry_into_hash(stocks[i], pos_date)
    }
  }

  if (!is.null(update_progress)) { update_progress(0.2, if (ENG == LANG) 'initialize data' else '初始化資料') }
  # prepare summary data pool
  start_date = as.integer(colnames(positions[[1]]))
  end_date = as.integer(colnames(positions[[length(positions)]]))  # find out if we can use '-1' to retrieve last element
  summary = get_initial_summary(start_date, end_date)

  if (!is.null(update_progress)) { update_progress(0.4, if (ENG == LANG) 'iterate data' else '累加資料') }
  # for each stock_id, fill in its 'contribution' to data pool
  for (stock_id in get_stocks_from_hash()) {
    buy_dates = get_stock_pos_date(stock_id)
    summary = add_summary(summary, stock_id, buy_dates)
  }

  if (!is.null(update_progress)) { update_progress(0.6, if (ENG == LANG) 'summarize data' else '總結資料') }
  for (i in 1:nrow(summary)) {
    if (summary$pos_cnt[i] > 0) {
      summary$ret_avg[i] = summary$ret_cumu[i] / summary$pos_cnt[i]
    }
  }

  if (!is.null(update_progress)) { update_progress(0.8) }
  return (summary)
}

get_return_from_summary <- function(summary, title)
{
  ret_values = matrix(summary$ret_avg)
  colnames(ret_values) = title
  return (xts(ret_values, as.Date(summary$date)))
}

get_return <- function(get_position_func, title, in_summary=NA)
{
  summary = if (class(in_summary) == 'logical' && is.na(in_summary)) # need '&&' to have short-curcuit evaluation
    get_evaluate_summary(get_position_func) else in_summary
  return (get_return_from_summary(summary, title))
}

evaluate <- function(get_position_func, title, in_summary=NA, update_progress=NULL)
{
  summary = if (class(in_summary) == 'logical' && is.na(in_summary)) # need '&&' to have short-curcuit evaluation
    get_evaluate_summary(get_position_func, update_progress) else in_summary
  ret = get_return_from_summary(summary, title)
  table.Drawdowns(ret, top=10)
  table.DownsideRisk(ret)
  charts.PerformanceSummary(ret)

  return (summary)
}

evaluate_pair_relative <- function(get_position_func1, title1, get_position_func2, title2, 
                                   in_summary1=NA, in_summary2=NA, update_progress=NULL)
{
  if (!is.null(update_progress)) { update_progress(0, paste0(if (ENG == LANG) 'compute ' else '計算', title1)) }
  ret1 = get_return(get_position_func1, title1, in_summary1)

  if (!is.null(update_progress)) { update_progress(0.01, paste0(if (ENG == LANG) 'compute ' else '計算', title2)) }
  ret2 = get_return(get_position_func2, title2, in_summary2)

  if (!is.null(update_progress)) { update_progress(0.6, if (ENG == LANG) 'draw relative graph' else '繪製「相對報酬」圖') }
  # Note: we've tried, but failed to find the 'PerformanceAnalytics' charts support Chinese
  chart.RelativePerformance(ret1, ret2, main=paste("Relative Performance:", title1, "to", title2))

  if (!is.null(update_progress)) { update_progress(0.9) }
}

evaluate_pair <- function(get_position_func1, title1, get_position_func2, title2, 
                          in_summary1=NA, in_summary2=NA, update_progress=NULL)
{
  if (!is.null(update_progress)) { update_progress(0, paste0(if (ENG == LANG) 'compute ' else '計算', title1)) }
  ret1 = get_return(get_position_func1, title1, in_summary1)

  if (!is.null(update_progress)) { update_progress(0.01, paste0(if (ENG == LANG) 'compute ' else '計算', title2)) }
  ret2 = get_return(get_position_func2, title2, in_summary2)

  if (!is.null(update_progress)) { update_progress(0.4, if (ENG == LANG) 'draw summary graph' else '繪製「報酬總結」圖') }
  ret_combine = cbind(ret1, ret2)
  colnames(ret_combine) = c(title1, title2)
  table.Drawdowns(ret_combine, top=10)
  table.DownsideRisk(ret_combine)
  charts.PerformanceSummary(ret_combine)

  if (!is.null(update_progress)) { update_progress(0.7, if (ENG == LANG) 'compute statistics' else '計算報酬相關數據') }
  cumu_returns = Return.cumulative(ret_combine)
  annual_returns = Return.annualized(ret_combine)
  
  first_valid_entry = which(ret1 != 0)[1]
  cumu_returns1 = Return.cumulative(ret1[first_valid_entry:length(ret1),])
  annual_returns1 = Return.annualized(ret1[first_valid_entry:length(ret1),])
  dd = findDrawdowns(ret1[first_valid_entry:length(ret1),])
  ldd = max(dd$length)
  ldd_entry = which(dd$length==ldd)[1] # only returns the result of 1st ldd entry
  ldd_from_date = as.character(index(ret_combine)[dd$from[ldd_entry] + first_valid_entry - 1])
  ldd_to_date = as.character(index(ret_combine)[dd$to[ldd_entry] + first_valid_entry - 1])
  start_month = index(ret_combine)[first_valid_entry - 1]
  start_month1 = paste0(format(start_month, '%Y'), '年', months(start_month))
  
  first_valid_entry2 = which(ret2 != 0)[1]
  cumu_returns2 = Return.cumulative(ret2[first_valid_entry2:length(ret2),])
  annual_returns2 = Return.annualized(ret2[first_valid_entry2:length(ret2),])
  dd2 = findDrawdowns(ret2[first_valid_entry2:length(ret2),])
  ldd2 = max(dd2$length)
  ldd_entry2 = which(dd2$length==ldd2)[1] # only returns the result of 1st ldd entry
  ldd_from_date2 = as.character(index(ret_combine)[dd2$from[ldd_entry2] + first_valid_entry2 - 1])
  ldd_to_date2 = as.character(index(ret_combine)[dd2$to[ldd_entry2] + first_valid_entry2 - 1])
  start_month = index(ret_combine)[first_valid_entry2 - 1]
  start_month2 = paste0(format(start_month, '%Y'),
    if (ENG == LANG) '' else '年',
    if (ENG == LANG) paste0('/', format(start_month, '%m')) else months(start_month))

  if (!is.null(update_progress)) { update_progress(0.8, if (ENG == LANG) 'return results' else '傳回結果') }
  return (data.frame(cumu_ret=c(cumu_returns1, cumu_returns2),
                     annual_ret=c(annual_returns1, annual_returns2),
                     start_month=c(start_month1, start_month2),
                     mdd=c(min(dd$return), min(dd2$return)),
                     ldd=c(ldd, ldd2),
                     from=c(ldd_from_date, ldd_from_date2),
                     to=c(if (is.na(ldd_to_date)) '' else ldd_to_date, 
                          if (is.na(ldd_to_date2)) '' else ldd_to_date2)))
}
