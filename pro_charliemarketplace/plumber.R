library(plumber)
library(odbc)
library(jsonlite)

#* @apiTitle Middleware layer to access pro_charliemarketplace custom tables
#* @apiDescription CRUD controls to schema storage

#* Echo back the input
#* @param msg The message to echo
#* @get /echo
function(msg = "") {
    list(msg = paste0("The message is: '", msg, "'"))
}


#' @filter cors
cors <- function(req, res) {
  
  res$setHeader("Access-Control-Allow-Origin", "*")
  
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$setHeader("Access-Control-Allow-Methods","*")
    res$setHeader("Access-Control-Allow-Headers", req$HTTP_ACCESS_CONTROL_REQUEST_HEADERS)
    res$status <- 200
    return(list())
  } else {
    plumber::forward()
  }
  
}

#* Internal function for accessing provided credentials 
#* @param query the SQL text  
#* @param driver the Snowflake Driver, typicially "Snowflake" on Prod, for local use your local ODBC Driver name.
#* @param user Snowflake username
#* @param pass Snowflake password (encrypt)
#* @param role Snowflake role to access
#* @param server Snowflake URL endpoint (no HTTP)
#* @param warehouse Snowflake warehouse to run the query.
#* @param database Optional, Snowflake database to query against, best practice is to put database in query, can be NULL
submitSnowflake <- function(query, driver = "Snowflake", user, pass, role, server, warehouse, database){
  
  connection <- dbConnect(
    odbc::odbc(),
    .connection_string = paste0("Driver={",driver,"}",
                                ";Server={",server,
                                "};uid=",user,
                                ";role=",role,
                                ";pwd=",pass,
                                ";warehouse=", warehouse,
                                ";database=", database)
  )
  
  output <- dbGetQuery(connection, query)
  dbDisconnect(connection)
  return(output)
  
}


#* Test function against private credentials, gitignored but provided to server 
#* @get /test_returns_1
test_server <- function(){
  private_credentials <- fromJSON("snowflake-details.json")
  
 x = submitSnowflake(query = "select 1 as result from DUAL", 
    # driver = "SnowflakeDSIIDriver",  # local
    driver = "Snowflake",  # prod 
    user = private_credentials$username,
    pass = private_credentials$password, 
    role = private_credentials$role,
    server = private_credentials$server_url,
    warehouse = private_credentials$warehouse,
    database = private_credentials$database
  )
 
 return(x)
  
}

#* Parse JSON structured requests
#* @post /check_request
#*
function(req) {
  # Parse the JSON body
  # Return the parsed JSON body
  headers <- req$HEADERS
  body <- req$postBody
  bb <<- req
  return(
    body
  )
}


#* Return a result from private storage
#* @apiDescription POST the results of a submitSnowflake() using provided query and credentials securely in the request body.
#* The post req should have JSON with query, user, pass, role, server, warehouse, and optional database, driver.
#* @post /submit_snowflake
function(req) {
  # Parse the JSON body from the request
  params <- jsonlite::fromJSON(req$postBody)
  pp <<- params
  # Extract parameters
  query <- params$query
  user <- params$user
  pass <- params$pass
  role <- params$role
  server <- params$server
  warehouse <- params$warehouse
  database <- ifelse(!is.null(params$database), params$database, NULL)
  
  result <- submitSnowflake(query = query, 
                           #  driver = "SnowflakeDSIIDriver",  # local
                            driver = "Snowflake",  # prod 
                            user = user,
                            pass = pass, 
                            role = role,
                            server = server,
                            warehouse = warehouse,
                            database = database)
  
  return(result)
}



# Programmatically alter your API
#* @plumber
function(pr) {
    pr %>%
        # Overwrite the default serializer to return unboxed JSON
        pr_set_serializer(serializer_unboxed_json())
}
