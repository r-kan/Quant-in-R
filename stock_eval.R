# Evaluation function of a given stock id

source('eval_util.R')

evaluate_stock <- function(id, update_progress=NULL)
{
  dprint(paste0('[stock_eval] evaluate_stock with ', id))
  stopifnot(class(id) == 'character')
  return (evaluate(function(dummy_input){return (id)}, id, update_progress=update_progress))
  #id_list = c('2303', '2002', '1101', '2891', '2408', '2884', '9904', '1326', '2474', '1303', '2330')
  #return (evaluate(function(dummy_input){return (id_list)}, "test_stock_group"))
}

evaluate_stock_pair_relative <- function(id1, id2)
{
  evaluate_pair_relative(stock_id_closure(id1), id1,
                         stock_id_closure(id2), id2)
}

evaluate_stock_pair <- function(id1, id2)
{
  evaluate_pair(stock_id_closure(id1), id1,
                stock_id_closure(id2), id2)
}
