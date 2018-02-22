
library(shiny)
library(DBI)
library(dplyr)
library(openssl)

# Database ----------------------------------------------------------------

DB_NAME <- "data.sqlite"
TBL_USER_DATA <- "users"

DB_test_connect <- function(){
  db <- dbConnect(RSQLite::SQLite(), DB_NAME)
  
  print("#######################")
  print("- Connected to Database")
  
  # If a user data table doesn't already exist, create one
  if(!(TBL_USER_DATA %in% dbListTables(db))){
    print("- Warning: No 'users' table found. Creating table...")
    df <- data.frame(ID = as.numeric(character()),
                     USER = character(),
                     HASH = character(),
                     stringsAsFactors = FALSE)
    dbWriteTable(db, TBL_USER_DATA, df)
  } 
  
  print("- Table exists.")
  print("#######################")
  
  dbDisconnect(db)
}

DB_upload_csv <- function(filename, tblname){
  db <- dbConnect(RSQLite::SQLite(), DB_NAME)
  
  df <- read.csv(file = filename, header = T, row.names = F, stringsAsFactors = F)
  
  dbWriteTable(db, tblname, df)
  
  dbDisconnect(db)
}

DB_get_user <- function(user){
  db <- dbConnect(RSQLite::SQLite(), DB_NAME)
  
  users_data <- dbReadTable(db, TBL_USER_DATA)
  
  hashusers_data <- filter(users_data, USER == user)
  
  dbDisconnect(db)
  
  return(users_data)
}

DB_add_user <- function(usr, hsh){
  db <- dbConnect(RSQLite::SQLite(), DB_NAME)
  
  df <- dbReadTable(db, TBL_USER_DATA)
  
  q <- paste("INSERT INTO", TBL_USER_DATA, "(ID, USER, HASH) VALUEs (", paste("", nrow(df), ",", usr, ",", hsh, "", sep="'"), ")")
  
  #print(q)
  
  dbSendQuery(db, q)
  
  suppressWarnings({dbDisconnect(db)})
  
}

# Init Database -----------------------------------------------------------

DB_test_connect()

# Server ------------------------------------------------------------------

shinyServer(function(input, output, session) {
  
  loggedIn <- reactiveVal(value = FALSE)
  user <- reactiveVal(value = NULL)
  
  login <- eventReactive(input$login, {
    
    user_data <- DB_get_user(input$username)
    
    if(nrow(user_data) > 0){ # If the active user is in the DB then logged in
      if(sha256(input$password) == user_data[1, "HASH"]){
        
        user(input$username)
        loggedIn(TRUE)
        
        print(paste("- User:", user(), "logged in"))
        
        return(TRUE)
      }
    }
    
    return(FALSE)
    
  })
  register_user <- eventReactive(input$register_user, {
    
    users_data <- DB_get_user(input$new_user)
    
    if(nrow(users_data) > 0){
      return(span("User already exists", style = "color:red"))
    }
    
    new_hash <- sha256(input$new_pw)
    new_user <- input$new_user
    
    DB_add_user(new_user, new_hash)
    
    print("- New user added to database")
    
    return(span("New user registered", style = "color:green"))
    
  })
  
  output$register_status <- renderUI({
    if(input$register_user == 0){
      return(NULL)
    } else {
      register_user()
    }
  })
  output$login_status <- renderUI({
    if(input$login == 0){
      return(NULL)
    } else {
      if(!login()){
        return(span("The Username or Password is Incorrect", style = "color:red"))
      }
    }
  })
  
  observeEvent(input$create_login, {
    showModal(
      modalDialog(title = "Create Login", size = "m", 
                textInput(inputId = "new_user", label = "Username"),
                passwordInput(inputId = "new_pw", label = "Password"),
                actionButton(inputId = "register_user", label = "Submit"),
                p(input$register_user),
                uiOutput("register_status")
                
                )
    )

    register_user()
    
  })
  observeEvent(input$logout, {
    user(NULL)
    loggedIn(FALSE)
    print("- User: logged out")
  })
  
  observe({
    if(loggedIn()){
      output$App_Panel <- renderUI({
        fluidPage(
          fluidRow(
            strong(paste("logged in as", user(), "|")), actionLink(inputId = "logout", "Logout"), align = "right",
            hr()
          ),
          fluidRow(
            titlePanel(title = "APP UI GOES Here"), align = "center"
          )
        )
        
      })
    } else {
      output$App_Panel <- renderUI({
        fluidPage(
          fluidRow(
            hr(),
            titlePanel(title = "App Name"), align = "center"
          ),
          fluidRow(
            column(4, offset = 4,
                   wellPanel(
                     h2("Login", align = "center"),
                     textInput(inputId = "username", label = "Username"),
                     passwordInput(inputId = "password", label = "Password"),
                     fluidRow(
                       column(4, offset = 4, actionButton(inputId = "login", label = "Login")),
                       column(4, offset = 4, actionLink(inputId = "create_login", label = "Create login")),
                       column(6, offset = 3, uiOutput(outputId = "login_status")
                       )
                     )
                   )
            )
          )
        )
      })
    }
  })
  

})
