# Utility functons and definitions of stock value type

# inspired by the following (somehow, their methods do not work for my usage)
# http://stackoverflow.com/questions/24309910/how-to-get-name-of-variable-in-r-substitute
vname <- function(var)  # return string name of var, e.g., vname("foo") = "foo"
{
  return (deparse(substitute(var)))
}

# Shall we try variable declaration with possible higher readability?
#  (this may be an issue when num. of var is larger...)
# ref.: http://stackoverflow.com/questions/7519790/assign-multiple-new-variables-in-a-single-line-in-r
yield = 1
date = 2
close = 3
volume = 4
adjclose = 5

YIELD = vname(yield)
DATE = vname(date)
CLOSE = vname(close)
VOLUME = vname(volume)
ADJCLOSE = vname(adjclose)

get_name <- function(value_type)
{
  switch (value_type,
    yield = "殖利率",
    date = "日期",
    close = "收盤價",
    volume = "成交量",
    adjclose = "還原權值價格")
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
  if (name == "還原權值價格") {
    return (vname(adjclose))
  }
  stopifnot(FALSE)
}
