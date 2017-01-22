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
[1] "( 1) 個股：2382, ＳＨＹ：3.492369"
[1] "( 2) 個股：2912, ＳＨＹ：3.453791"
[1] "( 3) 個股：2801, ＳＨＹ：3.261258"
[1] "( 4) 個股：1101, ＳＨＹ：3.043907"
[1] "( 5) 個股：2207, ＳＨＹ：2.488453"
[1] "( 6) 個股：2330, ＳＨＹ：2.483946"
[1] "( 7) 個股：2325, ＳＨＹ：2.354444"
[1] "( 8) 個股：2357, ＳＨＹ：2.090429"
[1] "( 9) 個股：2354, ＳＨＹ：1.791885"
[1] "(10) 個股：0050, ＳＨＹ：NA"
[1] "(11) 個股：2408, ＳＨＹ：NA"
```

# How good (or bad) is SHY? 
Would you like to believe a strategy is good when someone throws it to you and claims that it is? I hope not.  
Here, I use `PerformanceAnalytics`, a powerful module in finance evaluation, to express the quality of SHY as follows:
```r
    source("shy_eval.R")
    eval_res = evaluate_shy()
```

The result is shown as the following graph in your RStudio console:
<a href="https://raw.githubusercontent.com/r-kan/r-kan.github.io/master/images/Quant-in-R/shy_perf.png" target="_blank"><img border="0" alt="show multiple yield values" src="https://raw.githubusercontent.com/r-kan/r-kan.github.io/master/images/Quant-in-R/shy_perf.png" width="515" height="411"></a>


In case that we are interested to the mutual performance between two targets, we can put the two targets in the same evaluation graph:
```r
    eval_pair_res = evaluate_shy_stock('2330')
```
<a href="https://raw.githubusercontent.com/r-kan/r-kan.github.io/master/images/Quant-in-R/shy_2330_perf.png" target="_blank"><img border="0" alt="show multiple yield values" src="https://raw.githubusercontent.com/r-kan/r-kan.github.io/master/images/Quant-in-R/shy_2330_perf.png" width="515" height="411"></a>

Another way to compare performance is to use a relative performance view:
```r
    eval_rel_res = evaluate_shy_stock_relative('2330')
```
<a href="https://raw.githubusercontent.com/r-kan/r-kan.github.io/master/images/Quant-in-R/shy_2330_perf_rel.png" target="_blank"><img border="0" alt="show multiple yield values" src="https://raw.githubusercontent.com/r-kan/r-kan.github.io/master/images/Quant-in-R/shy_2330_perf_rel.png" width="515" height="411"></a>

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
