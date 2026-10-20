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
  ),
  
  ## theme
  theme = bslib::bs_theme(version = 5, preset = 'flatly'),

  ## main layout
  bslib::layout_sidebar(
    fillable = TRUE,
    sidebar = bslib::sidebar(
      width = 350,
      title = NULL,

      ## EPA benchmark
      shiny::numericInput('loc_input', 'EPA Level of Concern (µg/L):', value = 1.0, step = 0.1, min = 0.1),
      
      shiny::hr(),
      shiny::p(shiny::strong('Legend:')),
      shiny::p('🔴 Exceeds LOC'),
      shiny::p('🟢 Below LOC'),
      shiny::p('⚪ Non-Detect (Censored)')
    ),
    
    ## column
    bslib::layout_columns(
      col_widths = c(12, 12),        
      row_heights = c(7, 3),          
      
      ## map
      bslib::card(
        full_screen = TRUE,
        leaflet::leafletOutput('water_map', height = '100%')
      ),
      
      ## time series
      bslib::card(
        shiny::plotOutput('trend_chart', height = '100%')
      )
    )
    
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
