#####################
## Shiny dashboard ##
#####################

library(shiny)

ui <- fluidPage(
  h3("EPA Atrazine Dashboard Diagnostics"),
  p("Testing WebR WASM boot sequence...")
)

server <- function(input, output, session) {}

shinyApp(ui, server)
