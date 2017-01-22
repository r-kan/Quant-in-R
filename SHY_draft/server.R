# server.R

source("shy.R")
source("stock_graph.R")

shinyServer(
  function(input, output)
  {
    v <- reactiveValues(enable_best3=FALSE)

    observeEvent(input$stock, { v$enable_best3 <- FALSE })
    observeEvent(input$valueType, { v$enable_best3 <- FALSE })
    observeEvent(input$best3, { v$enable_best3 = !v$enable_best3 })

    output$text <- renderText({
      if (v$enable_best3) { return ("最佳ＳＨＹ個股") }
      shy = get_shy(paste0(CSV_HOME, input$stock, '.csv'))
      paste("夏普殖利率: ", round(shy, 2))
    })

    output$plot <- renderPlot({
      if (v$enable_best3) { show_multi_graph_on_yield(as.vector(get_shy_suggestion()$id)) }
      else { show_graph(input$stock, get_value_name(input$valueType)) }
    })
  }
)

