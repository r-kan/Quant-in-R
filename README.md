# Quant-in-R
simple financial applications &amp; analysis programs written in R language

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
[1] "個股：2382, 夏普殖利率：3.466853"
[1] "個股：2912, 夏普殖利率：3.451974"
[1] "個股：2357, 夏普殖利率：2.663984"
[1] "個股：2207, 夏普殖利率：2.491292"
[1] "個股：2330, 夏普殖利率：2.470229"
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

# How good (or bad) is SHY? 
Would you like to believe a strategy is good when someone throws it to you and claims that it is good? I hope not.  
Next, I would like to present R programs to show the quality of SHY, basically, in terms of returns on investment. The result will also be compared with one of the most popular long-term investment target, 0050 etf.  I believe that way using R, think and evaluate our financial decisions before applying them, will give us invaluable feedback.

# More advanced R programs
Next, I will present programs utilize more advaned R features on the following:  
* Probability Distributions
* Linear Least Square Regression
* Confidence Intervals
* pValues
* Power of a test
