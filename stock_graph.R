# Create graph file for stock values

if (!exists('UTIL_R')) {
  source('util.R')
}

WIDTH = 800
HEIGHT = 450
RES = 100
POINT_SIZE = .1

show_graph <- function(id, value_type=YIELD)
{
  csv_data = get_csv_data(get_csv_file(id))
  stopifnot(FALSE == is.na(csv_data))

  par(mar=c(4,4,2,2)+0.1) # bottom, left, top, and right (default: 4.1)
  plot(as.Date(sapply(csv_data[nrow(csv_data):1, DATE], to_date), origin='1970-01-01'),
       csv_data[nrow(csv_data):1, value_type],
       cex=POINT_SIZE, type="o", col="red", xlab=DATE,
       ylab=value_type, main=paste(value_type, "chart"))
}

dump_graph <- function(id, value_type=YIELD)
{
  png(file="stock.png", width=WIDTH, height=HEIGHT, res=RES)
  show_graph(id, value_type)
  dev.off() 
}

library(ggplot2)

show_close_and_adjclose <- function(id)
{
  dprint('[stock_graph] show_close_and_adjclose')
  csv_data = get_csv_data(get_csv_file(id), cared_value=c(DATE, CLOSE, ADJCLOSE))
  stopifnot(FALSE == is.na(csv_data))
  min_price = min(csv_data[, CLOSE], na.rm=TRUE)
  max_price = max(csv_data[, ADJCLOSE], na.rm=TRUE)

  price_frame = data.frame(date=as.Date(sapply(csv_data[nrow(csv_data):1, DATE], to_date), origin='1970-01-01'),
                           close=csv_data[nrow(csv_data):1, CLOSE],
                           adjclose=csv_data[nrow(csv_data):1, ADJCLOSE])
  p = ggplot(price_frame, aes(x=date, y=c(close))) + 
    ggtitle(paste0(id, if (ENG == LANG) ' Adjusted Close' else '還原權值股價圖')) +
    geom_line(aes(y=adjclose, colour=if (ENG == LANG) 'adjusted close' else '還原權值價格')) +
    geom_line(aes(y=close, colour=if (ENG == LANG) 'close' else '收盤價')) +
    theme(legend.justification=c(0,1), legend.position=c(.03, .97), legend.title=element_text(size=0)) +
    xlab(if (ENG == LANG) 'Date' else get_name(DATE)) + ylab(if (ENG == LANG) 'Price' else '價格') +
    theme(text=element_text(family='STKaiti')) # to support Chinese characters
  print(p)
}

  # the following is 'plot' version for 'show_close_and_adjclose'
  "par(mar=c(4,4,2,2)+0.1) # bottom, left, top, and right (default: 4.1)
  par(family='STKaiti') # to support Chinese characters
  plot(as.Date(sapply(csv_data[nrow(csv_data):1, DATE], to_date)),
       csv_data[nrow(csv_data):1, CLOSE],
       cex=POINT_SIZE, type='o', col='lightblue',
       ylim=c(min_price, max_price),
       xlab=get_name(DATE), ylab='價格', main=paste0(id, '還原權值股價圖'))
  lines(as.Date(sapply(csv_data[nrow(csv_data):1, DATE], to_date)),
        csv_data[nrow(csv_data):1, ADJCLOSE],
        cex=POINT_SIZE, type='o', col='blue')

  legend('topleft', inset=.05, cex=1,
         c(get_name(CLOSE), get_name(ADJCLOSE)),
         horiz=FALSE, lty=c(1,1), lwd=c(2,2),
         col=c('lightblue', 'blue'),
         bg='grey96')"

show_multi_graph_on_yield <- function(id_list)
{
  input_cnt = length(id_list)
  stopifnot(input_cnt >= 1)

  max_cnt = 3
  if (input_cnt > max_cnt) {
    input_cnt = max_cnt
    print(paste0("最多支援的個股數為", max_cnt, ", 其餘的個股將不予處理"))
  }

  par(mar=c(4,4,2,2)+0.1) # bottom, left, top, and right (default: 4.1)

  max_date_cnt = 0
  max_yield = 0
  min_yield = MAX_YIELD_BOUND
  data_list = list()
  shy_list = double(length(input_cnt))

  for (i in 1:input_cnt)
  {
    csv_data = get_csv_data(get_csv_file(id_list[i]))
    stopifnot(FALSE == is.na(csv_data))

    max_date_cnt = max(nrow(csv_data), max_date_cnt)
    max_yield = max(max(csv_data[, YIELD], na.rm=TRUE), max_yield)
    positive_indices = csv_data[, YIELD] > 0
    this_min_yield = min(csv_data[, YIELD][positive_indices], na.rm=TRUE)
    min_yield = min(this_min_yield, min_yield)

    shy_list[i] = get_shy(csv_file, data=csv_data)
    data_list[[i]] = csv_data
  }

  color_list = c("red", "blue", "green")
  par(family='STKaiti') # to support Chinese characters
  plot(as.Date(sapply(data_list[[1]][max_date_cnt:1, DATE], to_date), origin='1970-01-01'),
       data_list[[1]][max_date_cnt:1, YIELD],
       xlab=DATE, ylab=YIELD,
       ylim=c(min_yield, max_yield),
       main=paste(YIELD, if (1 == length(id_list)) "chart" else "comparison"),
       cex=POINT_SIZE, type="o", col=color_list[1])

  axis(side=2, at=c(0:max_yield))

  if (input_cnt >= 2) 
  {
    for (i in 2:input_cnt) {
      lines(as.Date(sapply(data_list[[i]][max_date_cnt:1, DATE], to_date), origin='1970-01-01'),
            data_list[[i]][max_date_cnt:1, YIELD],
            cex=POINT_SIZE, type="o", col=color_list[i])
    }
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
}

dump_multi_graph_on_yield <- function(shy_res_list)
{
  png(file="yield.png", width=WIDTH, height=HEIGHT, res=RES)
  show_multi_graph_on_yield(as.vector(shy_res_list$id))
  dev.off() 
}
