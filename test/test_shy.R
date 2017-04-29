# test suite

library(testthat)

source('test_util.R')
source('shy.R')
source('stock_eval.R')

TEST_UNTIL_DATE = as.Date('2016-12-30')

# shy computation
test_that("shy computation",{
  res_pair = get_shy_values('csv/2330.csv', TEST_UNTIL_DATE)
  expect_true(is_small_difference(res_pair$shy, 2.489083))
  expect_true(is_small_difference(res_pair$adjust_factor, 66.58078))
})

# this way, the variable can be set globally, ref.: http://stackoverflow.com/questions/1236620/global-variables-in-r
assign('FINISH_EVAL_DATE', TEST_UNTIL_DATE, envir = .GlobalEnv)

# stock evaluation
test_that("stock evaluation",{
  assign('EVAL_PERIOD_LEN', 63, envir = .GlobalEnv)
  res = evaluate_stock('2330')
  expect_true(is_small_difference(sum(res$ret_cumu), 45.03131))
})

# shy evaluation
test_that("shy evaluation",{
  # single round shy position computation on a limited csv file input
  pos = get_shy_suggestion(in_csv_files=get_csv_files(c('1434', '2701')), silence=TRUE)
  expect_true(is_small_difference(pos$shy[1], 3.922772))
  expect_true(is_small_difference(pos$shy[2], 3.452148))

  assign('EVAL_PERIOD_LEN', 2463, envir = .GlobalEnv)
  # evalution under some small amount of positions
  res = evaluate(id_list_closure(as.vector(pos$id)), 'test_shy_eval')  # note: we don't direct test 'evaluate_shy'
  expect_true(is_small_difference(sum(res$ret_cumu), 2.267973))
})
