# Quant-in-R
simple financial applications &amp; analysis programs written in R language   
  
2016/10/10: A draft version of <a href='https://rkan.shinyapps.io/SHY_draft/'>SHY web interface</a> is presented

# R, as a programming language
The R programming language is designed for statistical analysis, and is widely used in many area recently. Here, I will focus on one of the most adopting domain, financial analysis, to demonstrate the strength of R.  Besides, I shall pay extra attention to data visualizaiton in R.  

# The SHY 'SHarpe Yield' strategy
The introduced investment strategy, SHY 'SHarpe Yield', has a very simple computation model. It evaluates each stock by the SHY value, simply **yield** represents in a **sharpe ratio** way, i.e., its **mean** divided by its **standard deviation**. Given a list of concerned stocks, it computes the SHY value, and reports the stocks from highest to lowest SHY value.  

Here, we have 10 stocks in the folder `csv/`, and `shy.R` works as follows:  
```r
    source("shy.R")
    shy_list = get_shy_suggestion()
```

Then, it shows
```
[1] "推薦個股（依評比由高至低）如下："
[1] "( 1) 個股：2382, 夏普殖利率：3.466853"
[1] "( 2) 個股：2912, 夏普殖利率：3.451974"
[1] "( 3) 個股：2801, 夏普殖利率：3.217884"
[1] "( 4) 個股：1101, 夏普殖利率：3.049088"
[1] "( 5) 個股：2207, 夏普殖利率：2.491292"
[1] "( 6) 個股：2330, 夏普殖利率：2.470229"
[1] "( 7) 個股：2325, 夏普殖利率：2.329518"
[1] "( 8) 個股：2357, 夏普殖利率：2.072297"
[1] "( 9) 個股：2354, 夏普殖利率：1.779792"
[1] "(10) 個股：2408, 夏普殖利率：NA"
```
Note: 'DEBUG=1' to show more message during computation  

# Visualize the data

Visualization is always a good idea for better comprehension:
```r
    source("stock_graph.R")
    dump_multi_graph_on_yield(shy_list)
```

Then we have `yield.png` in working directory:
<a href="https://raw.githubusercontent.com/r-kan/r-kan.github.io/master/images/Quant-in-R/yield.png" target="_blank"><img border="0" alt="show multiple yield values" src="https://raw.githubusercontent.com/r-kan/r-kan.github.io/master/images/Quant-in-R/yield.png" width="800" height="450"></a>

We also can visualize the values in csv files as follows (`stock.png` will be genereated):
```r
    dump_graph("2330", "close")
```

<a href="https://raw.githubusercontent.com/r-kan/r-kan.github.io/master/images/Quant-in-R/stock.png" target="_blank"><img border="0" alt="close values of 2330" src="https://raw.githubusercontent.com/r-kan/r-kan.github.io/master/images/Quant-in-R/stock.png" width="800" height="450"></a>

For web interface visualization, check <a href='https://rkan.shinyapps.io/SHY_draft/'>SHY_draft</a> (powered by <a href='https://github.com/rstudio/shiny'>Shiny</a>).  

# How good (or bad) is SHY? 
Would you like to believe a strategy is good when someone throws it to you and claims that it is good? I hope not.  
Next, I would like to present R programs, adopting `quatmod` and `PerformanceAnalytics` to show the quality of SHY, basically in terms of returns on investment. The result will also be compared with one of the most popular long-term investment target in Taiwan stock market, the 0050 ETF. I believe in this way using R, to think and evaluate financial decisions before adopting them, gives invaluable benefit.  

# More R programs
For future plan, I will present programs utilize some other R features:  
* Probability Distributions
* Linear Least Square Regression
* Confidence Intervals
* pValues
* Power of a test
