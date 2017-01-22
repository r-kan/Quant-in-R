# ui.R

source("util.R")

stock_list <- get_aval_stock_list()

shinyUI(fluidPage(
  titlePanel("SHY"),
  
  sidebarLayout(
    sidebarPanel(
      helpText("The Sharpe Yield (SHY) strategy"),
      
      selectInput("stock",
        label = "選擇個股",
        choices = stock_list,
        selected = stock_list[0]),

      selectInput("valueType",
        label = "選擇種類",
        choices = c(get_name(close),
                    get_name(volume),
                    get_name(yield),
                    get_name(adjclose)),
        selected = get_name(close)),

      actionButton("best3", label = "最佳ＳＨＹ"),
      br(),
      br(),
      a(href="https://github.com/r-kan/Quant-in-R", "Check source code here")
    ),
    
    mainPanel(
      textOutput("text"),
      plotOutput('plot')
    )
  )
))

