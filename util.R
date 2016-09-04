# Common utility functions

if (!exists("DEBUG", mode="numeric"))
  DEBUG = 0

MAX_YIELD_BOUND = 99999
CSV_HOME = "csv/"

dprint <- function(msg)
{
  if (DEBUG) {
    print(msg)
  }
}

# inspired by the following (somehow, their methods do not work for my usage)
# http://stackoverflow.com/questions/24309910/how-to-get-name-of-variable-in-r-substitute
vname <- function(var)
{
  return (deparse(substitute(var)))
}
