#####################
## Shiny dashboard ##
#####################

########
## UI ##
########

ui <- bslib::page_fillable(
  
  ## header  
  shiny::div(
    class = 'p-3 bg-primary text-white',
    shiny::h3('Surface Water Quality Conditions: Atrazine in Iowa'),
    shiny::p('Tracking Estimated Environmental Concentrations (EECs) against EPA Aquatic Life Benchmarks.')
  )
  
)

############
## Server ##
############

server <- function(input, output, session) {
  
}

#########
## App ##
#########

shinyApp(ui, server)
