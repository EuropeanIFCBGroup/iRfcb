# Define UI
ui <- fluidPage(
  titlePanel("IFCB image gallery"),
  sidebarLayout(
    sidebarPanel(
      tags$label("Path to folder containing .png images:"),
      textInput("path", NULL, placeholder = "e.g., C:/path/to/taxon_images"),
      actionButton("go", "Go"),
      downloadButton("download", "List of selected images"),
      fileInput("upload", "Upload text file and apply image filter"),
    ),
    mainPanel(
      fluidRow(
        column(6, actionButton("prev_top", "Previous")),
        column(6, actionButton("next_top", "Next"))
      ),
      uiOutput("gallery"),
      fluidRow(
        column(6, actionButton("prev", "Previous")),
        column(6, actionButton("next_button", "Next"))
      ),
      selectInput("imagesPerPage", "Images per page:",
                  choices = c(20, 50, 100),
                  selected = 100),
      tags$div(id = "log_info"),
      actionButton("select_all", "Select All on Page"),
      actionButton("unselect_all", "Unselect All on Page"),
      fluidRow(
        column(12, uiOutput("page_info"))
      )
    )
  )
)
