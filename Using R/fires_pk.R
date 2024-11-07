libs <- c("tidyverse", "data.table",
           "ggmap", "sf","dplyr", "gganimate"
           )
installed_libs <- libs %in% rownames(installed.packages(
  
))

if(any(installed_libs==F)){
  install.packages(
    libs[!installed_libs]
  )
}

invisible(lapply(libs, library, character.only = T))

# # 66.135358,22.963632,76.635550,37.126052
# 
# xmin <- 18.7
# ymin<- 22.9
# xmax <- 66.1
# ymax <- 42.1
# 
# area_bbox <- c(xmin,
#                ymin, 
#                xmax,
#                ymax
# )
# 
# area <- paste(
#   area_bbox, 
#   sep = ",",
#   collapse = ","
# )

### Fire data

# # api = "7d1485ca49b2037707e6b49a3e1aa7db"
# api_key = "7d1485ca49b2037707e6b49a3e1aa7db"
# get_fire_data <- function(
#     url,
#     map_key,
#     source,
#     area,
#     day_range,
#     date){
#   url<-paste(url,
#              map_key,
#              source,
#              area,
#              day_range,
#              date,
#              sep = "/")
#   
#   fire_data<- data.table::fread(url)
#   return(fire_data)
#   
#   }
# main_url

### Making Animated Map


# Define individual folder paths
folder_paths <- c("C:\\Users\\Khizer Zakir\\Downloads\\fire_pk\\DL_FIRE_J1V-C2_35597",
                  "C:\\Users\\Khizer Zakir\\Downloads\\fire_pk\\DL_FIRE_SV-C2_35599",
                  "C:\\Users\\Khizer Zakir\\Downloads\\fire_pk\\DL_FIRE_M-C61_35596",
                  "C:\\Users\\Khizer Zakir\\Downloads\\fire_pk\\DL_FIRE_J2V-C2_35598")

# Define shapefile names
shapefile_names <- c("fire_nrt_J1V-C2_35597.shp", 
                     "fire_nrt_SV-C2_35599.shp", 
                     "fire_nrt_M-C61_35596.shp", 
                     "fire_nrt_J2V-C2_35598.shp")

# Create full file paths
shapefile_paths <- file.path(folder_paths, shapefile_names)

# Function to read and process each shapefile
process_shapefile <- function(file_path) {
  st_read(file_path) %>% 
    mutate(CONFIDENCE = as.character(CONFIDENCE))
}

# Load and process each shapefile, storing them in a list
aoi_list <- lapply(shapefile_paths, process_shapefile)

# Access individual shapefiles if needed
aoi1 <- aoi_list[[1]]
aoi2 <- aoi_list[[2]]
aoi3 <- aoi_list[[3]]
aoi4 <- aoi_list[[4]]




all_aois <- bind_rows(aoi1, aoi2, aoi3, aoi4)
# 3. BACKGROUND
#--------------

your_api_key = "08a28308-9b8f-4208-b22a-7e24e8bc6016"
ggmap::register_stadiamaps(key = your_api_key)

area_bbox <- c(left = 60.87, bottom = 23.67, right = 77.84, top = 37.06)

# Get the map
bg_layer <- ggmap::get_stadiamap(
  bbox = area_bbox,
  zoom = 7,
  maptype = "stamen_terrain",
  color = "bw",
  force = TRUE
)

ggmap::ggmap(bg_layer)

# 4. THEME
#----------

theme_for_the_win <- function(){
  theme_void() +
    theme(
      legend.position = "right",
      legend.title = element_text(
        size = 10, color = "grey10"
      ),
      legend.text = element_text(
        size = 9, color = "grey10"
      ),
      plot.title = element_text(
        size = 14, color = "grey10",
        hjust = .5
      ),
      plot.subtitle = element_text(
        face = "bold",
        size = 12, color = "firebrick",
        hjust = .5
      ),
      plot.caption = element_text(
        size = 10, color = "grey30",
        hjust = .5, vjust = 1
      ),
      plot.margin = unit(
        c(t = 1, r = 1, b = 1, l = 1),
        "lines"
      )
    )
}

# Updated MAP
#------------

all_aois$datum <- as.Date(
  all_aois$ACQ_DATE
)

p <- ggmap::ggmap(bg_layer) +
  geom_point(
    data = all_aois,
    aes(
      x = LONGITUDE,
      y = LATITUDE,
      color = BRIGHT_T31 - 273.15,
      group = datum
    ),
    inherit.aes = F
  ) +
  scale_color_gradientn(
    name = "Brightness\ntemperature\n(°C)",
    colors = rev(hcl.colors(
      6, "Inferno"
    ))
  ) +
  theme_for_the_win() +
  labs(
    title = "Crop Fires 01 SEP - 30 OCT 2024",
    subtitle = "{as.Date(frame_time)}",
    caption = "Source: NASA FIRMS Data"
  )

p

# 6. ANIMATE
#-----------

# Define the animation with adjustments
timelapse_map <- p +
  gganimate::transition_time(
    time = as.Date(datum)
  ) +
  gganimate::shadow_mark() +
  gganimate::enter_fade() +
  gganimate::exit_fade() +
  gganimate::ease_aes(
    "cubic-in-out",
    interval = .15  # Adjusted interval
  )

# Create the animated map with specified DPI
animated_map <- gganimate::animate(
  timelapse_map,
  nframes = 60,
  duration = 12,
  start_pause = 3,
  end_pause = 30,
  width = 7,
  height = 7,
  units = "in",
  res = 500,   # Set to 500 DPI
  fps = 15,
  renderer = gifski_renderer(loop = TRUE)
)

# Save animation to a specific location
gganimate::anim_save(
  "C:/Users/Khizer Zakir/Downloads/fire_pk/fire-pakistan_1.gif",  # Specify full path
  animated_map
)

# Print the animation to confirm it generated correctly
#print(animated_map)

