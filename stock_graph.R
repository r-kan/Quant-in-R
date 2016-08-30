# Create graph file for stock values

if (!exists("get_cared_data", mode="function"))
  source("shy.R")

stopifnot(exists("get_cared_data", mode="function"))

width = 800
height = 450
res = 100
point_ratio = .1

dump_graph <- function(id, value_type="yield")
{
  csv_file = paste(c("csv/", id, ".csv"), collapse='')
  cared_data = get_cared_data(csv_file, c("yield", "date", "close", "volume"))
  
  png(file=stock.png, width=width, height=height, res=res)
  par(mar=c(4,4,2,2)+0.1) # bottom, left, top, and right (default: 4.1)
  plot(cared_data[nrow(cared_data):1,value_type], 
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

  value_type = "yield"
  max_date_cnt = 0
  max_yield = 0
  max_yield_idx = 0
  data_list = list()
  shy_list = double(length(input_cnt))
  
  for (i in 1:input_cnt) 
  {
    csv_file = paste(c("csv/", id_list[i], ".csv"), collapse='')
    cared_data = get_cared_data(csv_file, c("yield", "date", "close", "volume"))
    shy_list[i] = get_shy(csv_file, cared_data)
    if (nrow(cared_data) > max_date_cnt) {
      max_date_cnt = nrow(cared_data)
    }
    this_max_yield = max(cared_data[, value_type], na.rm=TRUE)
    if (this_max_yield > max_yield) {
      max_yield = this_max_yield
      max_yield_idx = i
    }
    data_list[[i]] = cared_data
  }

  color_list = c("red", "blue", "green")
  par(family='STKaiti') # to support Chinese characters
  plot(data_list[[max_yield_idx]][max_date_cnt:1, value_type], 
       xlab="date", ylab=value_type, 
       main=paste(value_type, if (1 == length(id_list)) "chart" else "comparison"),
       cex=point_ratio, type="o", col=color_list[max_yield_idx])

  axis(side=2, at=c(0:max_yield)) # TODO: also show date as x-axis label in a readable way
  
  for (i in 1:input_cnt) {
    if (i == max_yield_idx) { next }
    lines(data_list[[i]][max_date_cnt:1, value_type], 
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
