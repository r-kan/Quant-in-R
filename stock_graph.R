# Create graph file for stock values

source("util.R")

if (!exists("get_csv_data", mode="function"))
  source("shy.R")

stopifnot(exists("get_csv_data", mode="function"))

width = 800
height = 450
res = 100
point_ratio = .1

dump_graph <- function(id, value_type="yield")
{
  csv_file = paste(c(CSV_HOME, id, ".csv"), collapse='')
  csv_data = get_csv_data(csv_file)
  
  png(file="stock.png", width=width, height=height, res=res)
  par(mar=c(4,4,2,2)+0.1) # bottom, left, top, and right (default: 4.1)
  plot(csv_data[nrow(csv_data):1,value_type], 
       cex=point_ratio, type="o", col="red", xlab="date", 
       ylab=value_type, main=paste(id, "chart"))
  
  dev.off() 
}

dump_multi_graph_on_yield <- function(id_list)
{
  input_cnt = length(id_list)
  stopifnot(input_cnt >= 1)
  
  max_cnt = 3
  if (input_cnt > max_cnt) {
    input_cnt = max_cnt
    print(paste(c("最多支援的個股數為", max_cnt, ", 其餘的個股將不予處理"), collapse=''))
  }
  
  png(file="yield.png", width=width, height=height, res=res)
  par(mar=c(4,4,2,2)+0.1) # bottom, left, top, and right (default: 4.1)

  YIELD = "yield"
  max_date_cnt = 0
  max_yield = 0
  min_yield = MAX_YIELD_BOUND
  data_list = list()
  shy_list = double(length(input_cnt))
  
  for (i in 1:input_cnt) 
  {
    csv_file = paste(c(CSV_HOME, id_list[i], ".csv"), collapse='')
    csv_data = get_csv_data(csv_file)
    max_date_cnt = max(nrow(csv_data), max_date_cnt)
    max_yield = max(max(csv_data[, YIELD], na.rm=TRUE), max_yield)
    this_min_yield = min(csv_data[, YIELD], na.rm=TRUE)
    if (0 != this_min_yield) {
      min_yield = min(this_min_yield, min_yield)
    }
    
    shy_list[i] = get_shy(csv_file, csv_data)
    data_list[[i]] = csv_data
  }

  color_list = c("red", "blue", "green")
  par(family='STKaiti') # to support Chinese characters
  plot(data_list[[1]][max_date_cnt:1, YIELD], 
       xlab="date", ylab=YIELD, 
       ylim=c(min_yield, max_yield),
       main=paste(YIELD, if (1 == length(id_list)) "chart" else "comparison"),
       cex=point_ratio, type="o", col=color_list[1])

  axis(side=2, at=c(0:max_yield)) # TODO: also show date as x-axis label in a readable way
  
  for (i in 2:input_cnt) {
    lines(data_list[[i]][max_date_cnt:1, YIELD], 
          cex=point_ratio, type="o", col=color_list[i])
  }
  
  legend_list = character(length(input_cnt))
  for (i in 1:input_cnt) {
    shy_str = format(round(shy_list[i], 2), nsmall = 2)
    legend_list[i] = paste(c(id_list[i], " (", shy_str, ")"), collapse='')
  }
  
  legend("topleft", inset=.05, cex=1,
         title = "個股 (夏普殖利率)",
         legend_list[1:input_cnt],
         horiz=FALSE, lty=c(1,1), lwd=c(2,2),
         col=color_list[1:input_cnt],
         bg="grey96")
  
  dev.off() 
}
