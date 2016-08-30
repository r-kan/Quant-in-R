# Quant-in-R
simple financial application &amp; analysis program written in R language

# R, as a programming language
The R programming language is designed for statistical analysis, and is widely used in many area recently. Here, I will focus on one of the most adopted domain, financial analysis, to demonstrate the strength or R.  Besides, I shall pay extra attention to data visualizaiton in R.  

# The SHY 'Sharpe Yield' strategy
The introduced investment strategy, SHY 'Sharpe Yield', has a very simple computation model. It evaluates each stock by the SHY value, simply **yield** represents in a **sharpe ratio** way, i.e., its **mean** divided by its **standard deviation**. Given a list of concerned stocks, it computes the SHY value, and reports the stocks from highest to lowest SHY value.  

Here, we already has 10 stocks in `csv/` directory, such that `shy.R` works as follows:  
```r
    source("shy.R")
    shy_list = get_shy_suggestion()
```

Then, it shows
```
[1] "個股：2408, 夏普殖利率：3.659004"
[1] "個股：2382, 夏普殖利率：3.466853"
[1] "個股：2912, 夏普殖利率：3.451974"
[1] "個股：2357, 夏普殖利率：2.663984"
[1] "個股：2207, 夏普殖利率：2.491292"
```

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

# More advanced R programs
Next, I will present programs utilize more advaned R features on the following:  
* Probability Distributions
* Linear Least Square Regression
* Confidence Intervals
* pValues
* Power of a test
