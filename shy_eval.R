# Evaluation function of SHY

source('setting.R')
source('eval_util.R')
source('shy.R')

# TODO: the SHY position serialization mechanism shall be better to be placed in a class

# The ShyPosition serialization --- begin

get_default_shy_pos <- function()
{
  shy_pos_entry = new.env()
  if (file.exists(SHY_POS_FILE)) 
  {
    shy_pos_data = read.csv(SHY_POS_FILE)
    row_cnt = nrow(shy_pos_data)
    if (row_cnt <= 0) { break }
    for (i in 1:row_cnt) 
    {
      shy_date_str = as.character(shy_pos_data$shy_date[i])
      pos_id_list = strsplit(as.character(shy_pos_data$id_list[i]), ',')[[1]]
      shy_pos_entry[[shy_date_str]] = pos_id_list
    }
  }
  return (shy_pos_entry)
}

ShyPosition = get_default_shy_pos()

clear_shy_pos_hash <- function()  # TODO: think when shall we call it (or we need it?)
{
  rm(list=names(ShyPosition), envir=ShyPosition)
}

set_id_entry_into_hash <- function(shy_date, pos_id_list)
{
  if (FALSE == CACHE_SHY_POS) { return () }

  shy_date_str = paste(shy_date)
  stopifnot(is.null(ShyPosition[[shy_date_str]]))
  ShyPosition[[shy_date_str]] = pos_id_list
  print(paste0("更新", SHY_POS_FILE, ", 加入資料日期", shy_date_str))
  shy_pos_frame = data.frame(shy_date=names(ShyPosition), 
                             id_list=sapply(names(ShyPosition), get_shy_pos_id_list_str, USE.NAMES=FALSE))
  write.csv(shy_pos_frame, SHY_POS_FILE, quote=FALSE, row.names=FALSE)  # not so smart, will write all data instead of this one
}

get_shy_pos_id_list <- function(shy_date)
{
  stopifnot(class(shy_date) == 'Date')
  shy_date_str = paste(shy_date)
  entry = ShyPosition[[shy_date_str]]
  if (is.null(entry)) {
    return (NA)
  }
  return (entry)
}

get_shy_pos_id_list_str <- function(shy_date)
{
  id_list = get_shy_pos_id_list(as.Date(shy_date))
  ret = ""
  for (stock_id in id_list) {
    ret = paste0(ret, stock_id, ",")
  }
  return (paste0('\"', substr(ret, 1, nchar(ret) - 1), '\"'))  # remove last ','
}
# The ShyPosition serialization --- end


# by given 'cared_date', get shy suggestion as positions and return
get_shy_position <- function(cared_date)
{
  pos_id_list = get_shy_pos_id_list(cared_date)
  if (class(pos_id_list) != 'logical') { # then, no way 'pos_id_list' is NA (for NA is of class 'logical')
    return (pos_id_list)
  }
  shy_res_list = get_shy_suggestion(cared_date, silence=TRUE)  # TODO: check size of shy_res_list
  pos_id_list = as.vector(shy_res_list$id[1:ADOPTED_SHY_POSITION_CNT])
  set_id_entry_into_hash(cared_date, pos_id_list)
  return (pos_id_list)
}

has_shy_summary <- function() { return (CACHE_SHY_SUMMARY && file.exists(SHY_SUMMARY_FILE)) }
get_shy_summary <- function() { return (if (has_shy_summary()) read.csv(SHY_SUMMARY_FILE) else NA) }

evaluate_shy <- function()
{
  print('[shy_eval] evaluate_shy')

  # this is not very good, but here, the value of FINISH_EVAL_DATE shall not be affected by any env. setting
  assign('FINISH_EVAL_DATE', Sys.Date(), envir = .GlobalEnv)

  # Note: the saved shy summary does not aware any evaluation setting, e.g., START_EVAL_DATE, EVAL_PERIOD_LEN
  cur_summary = evaluate(get_shy_position, "SHY", get_shy_summary())
  if (CACHE_SHY_SUMMARY && FALSE == has_shy_summary()) {  # we currently only save shy summary when calls 'evaluate_shy'
    print("儲存SHY summary")  
    write.csv(cur_summary, SHY_SUMMARY_FILE, quote=FALSE, row.names=FALSE)
  }
  
  return (cur_summary)
}

evaluate_shy_stock_relative <- function(stock_id, update_progress=NULL)
{
  dprint(paste0('[shy_eval] evaluate_shy_stock_relative with ', stock_id))
  evaluate_pair_relative(get_shy_position, "SHY",
                         stock_id_closure(stock_id), stock_id,
                         get_shy_summary(), update_progress=update_progress)
}

evaluate_shy_stock <- function(stock_id, update_progress=NULL)
{
  dprint(paste0('[shy_eval] evaluate_shy_stock with ', stock_id))
  return(evaluate_pair(get_shy_position, "SHY",
                stock_id_closure(stock_id), stock_id,
                get_shy_summary(), update_progress=update_progress))
}
