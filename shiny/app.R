#####################
## Shiny dashboard ##
#####################

## load data
atrazine_data <- readr::read_csv('cleaned_atrazine_iowa.csv', show_col_types = FALSE) |>
  dplyr::mutate(date = as.Date(date), year_month = lubridate::floor_date(date, 'month'))

## get IA outline
iowa <- paste(readLines('iowa_boundary.geojson', warn = FALSE), collapse = '')

## bounding box
bbox <- c(
  xmin = -96.63796,
  ymin = 40.37952,
  xmax = -90.14028,
  ymax = 43.50096
)

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
      
      ## slider
      shiny::sliderInput(inputId = 'time_slider', 
                         label = 'Select Month/Year:', 
                         min = min(atrazine_data$year_month), 
                         max = max(atrazine_data$year_month), 
                         value = min(atrazine_data$year_month), 
                         timeFormat = '%Y-%m', 
                         step = 31, 
                         animate = shiny::animationOptions(interval = 1500, loop = FALSE)),
      
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
  
  ## reactive: filter data for the exact month selected on the slider
  current_month_data <- shiny::reactive({ 
    shiny::req(input$time_slider)
    slider_month_str <- format(as.Date(input$time_slider), '%Y-%m')
    atrazine_data |> 
      dplyr::filter(format(year_month, '%Y-%m') == slider_month_str) |>
      dplyr::mutate(status = dplyr::case_when(is_non_detect ~ 'Non-Detect',
                                              conc_ug_L > input$loc_input ~ 'Exceeds LOC',
                                              TRUE ~ 'Below LOC'),
                    color = dplyr::case_when(status == 'Non-Detect' ~ 'grey',
                                             status == 'Exceeds LOC' ~ 'red',
                                             status == 'Below LOC' ~ '#28a745')
      )
  })
  
  ## reactive: aggregate data for the bottom trend chart up to current date
  trend_data <- shiny::reactive({
    shiny::req(input$loc_input)
    atrazine_data |> 
      dplyr::mutate(exceeds = ifelse(!is_non_detect & conc_ug_L > input$loc_input, 1, 0)) |>
      dplyr::group_by(year_month) |>
      dplyr::summarize(
        total_samples = dplyr::n(),
        exceedances = sum(exceeds, na.rm = TRUE),
        percent_exceed = (exceedances / total_samples) * 100,
        .groups = 'drop'
      )
  })
  
  ## map
  output$water_map <- leaflet::renderLeaflet({
      leaflet::leaflet() |>
        leaflet::addTiles(
          urlTemplate = 'https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/tile/{z}/{y}/{x}',
          attribution = 'USGS The National Map',
          options = leaflet::tileOptions(maxZoom = 16),
          group = 'USGS Topo'
        ) |>
        leaflet::addTiles(
          urlTemplate = 'https://basemap.nationalmap.gov/arcgis/rest/services/USGSImageryTopo/MapServer/tile/{z}/{y}/{x}',
          attribution = 'USGS Imagery',
          options = leaflet::tileOptions(maxZoom = 16),
          group = 'Satellite (Topo)'
        ) |>
        leaflet::addLayersControl(
          baseGroups = c('USGS Topo', 'Satellite (Topo)'),
          options = leaflet::layersControlOptions(collapsed = FALSE)
        ) |>
        leaflet::addGeoJSON(geojson = iowa, color = 'orange', weight = 5, fill = FALSE) |> 
        leaflet::fitBounds(unname(bbox[1]), unname(bbox[2]), unname(bbox[3]), unname(bbox[4]))
  })
  
  ## update map
  ## use leafletProxy to prevent the map from flashing/reloading
  shiny::observe({
    leaflet::leafletProxy('water_map', data = current_month_data()) |> 
      leaflet::clearMarkers() |> 
      leaflet::addCircleMarkers(
        ~longitude, ~latitude,
        radius = ~ifelse(status == 'Exceeds LOC', 8, 5), 
        color = ~color,
        fillOpacity = 0.8,
        stroke = TRUE,
        weight = 1,
        popup = ~paste0(
          '<b>Station:</b> ', station_id, '<br>',
          '<b>Date:</b> ', date, '<br>',
          '<b>Concentration:</b> ', round(conc_ug_L, 2), ' µg/L<br>',
          '<b>Status:</b> ', status
        )
      )
  })
  
  ## time series
  output$trend_chart <- shiny::renderPlot({
    ggplot2::ggplot(trend_data(), ggplot2::aes(x = year_month, y = percent_exceed)) +
      ggplot2::geom_line(color = 'darkgray', linewidth = 1) +
      ggplot2::geom_point(color = 'black') +
      ggplot2::geom_vline(xintercept = as.Date(input$time_slider), color = 'red', linetype = 'dashed', size = 1) +
      ggplot2::theme_minimal() +
      ggplot2::labs(
        x = 'Date',
        y = '% Exceeding LOC'
      ) +
      ggplot2::theme(text = ggplot2::element_text(size = 14))
  })
  
}

#########
## App ##
#########

shinyApp(ui, server)
