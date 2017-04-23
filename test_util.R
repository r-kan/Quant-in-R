# utility functions for testing

EPSILON = 0.00001

is_small_difference <- function(value1, value2)
{
  if (value1 == value2) { return (TRUE) }
  if (value1 > value2) { return (value2 + EPSILON >= value1) }
  if (value2 > value1) { return (value1 + EPSILON >= value2) }
  return (FALSE)
}

get_csv_files <- function(id_list)
{
  id_cnt = length(id_list)
  csv_files = character(id_cnt)
  for (i in 1:id_cnt) {
    csv_files[i] = get_csv_file(id_list[i])
  }

  return (csv_files)
}

id_list_closure <- function(id_list)
{
  function(dummy_input) id_list
}
