
source("util.R")

# TODO: try variable declaration with possible higher readability
#  (this will be an issue when num. of var is larger...)
# ref.: http://stackoverflow.com/questions/7519790/assign-multiple-new-variables-in-a-single-line-in-r
yield = 1
date = 2
close = 3
volume = 4

get_name <- function(value_type)
{
  switch (value_type,
    yield = "殖利率",
    date = "日期",
    close = "收盤價",
    volume = "成交量")
}

get_value_name <- function(name)
{
  if (name == "殖利率") {
    return (vname(yield))
  }
  if (name == "日期") {
    return (vname(date))
  }
  if (name == "收盤價") {
    return (vname(close))
  }
  if (name == "成交量") {
    return (vname(volume))
  }
  stopifnot(FALSE)
}