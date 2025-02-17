# Define server logic
server <- function(input, output, session) {
  shiny::addResourcePath("session", tempdir())
  images <- reactiveVal(NULL)
  current_page <- reactiveVal(1)
  images_per_page <- reactiveVal(20)
  clicked_images <- reactiveVal(character(0)) # Store clicked images
  class_folder <- reactiveVal(NULL) # Store the last folder in the path

  observeEvent(input$go, {
    # Validate path input
    if (is.null(input$path) || input$path == "") {
      return()
    }

    # Reset clicked_images
    clicked_images(NULL)

    # Replace backslashes with forward slashes
    path <- gsub("\\\\", "/", input$path)

    # Get last folder in the path
    folders <- unlist(strsplit(path, "/"))
    class_folder(folders[length(folders)])

    # Get list of files in the directory
    files <- list.files(path, full.names = TRUE)

    # Filter only images
    images(files[grep("\\.png$", files, ignore.case = TRUE)])
    current_page(1)
  })

  observeEvent(input$upload, {
    req(input$upload)
    uploaded_text <- read.table(input$upload$datapath, header = TRUE, sep = "\t")
    uploaded_images <- uploaded_text$image_filename
    filtered_images <- images()[basename(images()) %in% uploaded_images]
    images(filtered_images)
  })

  output$gallery <- renderUI({
    if (is.null(images()) || length(images()) == 0) {
      return(tags$p("No images found in the specified directory."))
    }

    temp_dir <- file.path(tempdir(), "shiny_images")
    dir.create(temp_dir, showWarnings = FALSE, recursive = TRUE)

    start_index <- (current_page() - 1) * as.numeric(images_per_page()) + 1
    end_index <- min(current_page() * as.numeric(images_per_page()), length(images()))

    tags$div(
      lapply(images()[start_index:end_index], function(image) {
        filename <- basename(image)
        temp_image_path <- file.path(temp_dir, filename)

        if (!file.exists(temp_image_path)) {
          file.copy(image, temp_image_path, overwrite = TRUE)
        }

        # Construct the proper src path for Shiny to serve
        image_url <- paste0("session/shiny_images/", filename)

        style <- ifelse(filename %in% clicked_images(), "color: red;", "color: black;")
        tags$div(
          tags$img(src = image_url,
                   style = "margin: 10px; cursor: pointer; max-width: 200px;",
                   onclick = paste0("Shiny.setInputValue('clicked_image', '", filename, "')")),
          tags$p(filename, id = filename,
                 style = paste("margin: 5px 10px; font-weight: bold;", style))
        )
      })
    )
  })

  observeEvent(input$prev, {
    if (current_page() > 1) {
      current_page(current_page() - 1)
    }
  })

  observeEvent(input$prev_top, {
    if (current_page() > 1) {
      current_page(current_page() - 1)
    }
  })

  observeEvent(input$next_button, {
    if (current_page() < ceiling(length(images()) / as.numeric(images_per_page()))) {
      current_page(current_page() + 1)
    }
  })

  observeEvent(input$next_top, {
    if (current_page() < ceiling(length(images()) / as.numeric(images_per_page()))) {
      current_page(current_page() + 1)
    }
  })

  observeEvent(input$imagesPerPage, {
    images_per_page(input$imagesPerPage)
  })

  observeEvent(input$clicked_image, {
    if (!input$clicked_image %in% clicked_images()) {
      clicked_images(c(clicked_images(), input$clicked_image))
    } else {
      clicked_images(clicked_images()[!clicked_images() %in% input$clicked_image])
    }
  })

  observeEvent(input$select_all, {
    start_index <- (current_page() - 1) * as.numeric(images_per_page()) + 1
    end_index <- min(current_page() * as.numeric(images_per_page()), length(images()))
    selected_images <- images()[start_index:end_index]
    clicked_images(union(clicked_images(), basename(selected_images)))
  })

  observeEvent(input$unselect_all, {
    start_index <- (current_page() - 1) * as.numeric(images_per_page()) + 1
    end_index <- min(current_page() * as.numeric(images_per_page()), length(images()))
    unselected_images <- images()[start_index:end_index]
    clicked_images(clicked_images()[!clicked_images() %in% basename(unselected_images)])
  })

  output$log_info <- renderText({
    paste("Clicked Images:", paste(clicked_images(), collapse = ", "))
  })

  output$page_info <- renderText({
    paste("Page", current_page(), "of", ceiling(length(images()) / as.numeric(images_per_page())))
  })

  # Generate and download text file with selected images summary
  output$download <- downloadHandler(
    filename = function() {
      paste(class_folder(), "_selected_images.txt", sep = "")
    },
    content = function(file) {
      selected_images <- data.frame(class_folder = class_folder(), image_filename = clicked_images())
      write.table(selected_images, file, sep = "\t", quote = FALSE, row.names = FALSE)
    }
  )
}
