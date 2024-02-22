# flipside_pro_middleware
 ODBC Middleware Layer for accessing Flipside Pro 

## Structure 

Flipside Pro comes with 1 TB of storage and full CRUD controls within your 
private Snowflake Schema. See: https://github.com/fsc-data-science/powered_by_flipside_pro 
for more details on building incremental models.

Using the Flipside Crypto Secrets Manager for LiveQuery, you can create a secret-environment
(here, `charlie_pro`) and add your Snowflake credentials: `server` `user` `pass` `role` `database`. 
Warehouse will always be PRO. 

You can then pass Queries, including procedure calls, views, CRUD, etc. as a request
and get the ouput back as JSON. NOTE: it is best to use views and procs to avoid 
situations where nested quotes have to be escaped (i.e., adding a block_timestamp filter
is a bit of a pain since it requires nested quotes within the request_query). Possible, but annoying.


```sql
/*
livequery.live.udf_api(
  [method,]
  url,
  [headers,]
  [data,]
[secret]
*/

with body AS (
-- NOTE, need to carefully manage single ' and double " quotes in query text
-- use escapes '' 

SELECT 
'CALL pro_charliemarketplace.tests.update_aggregated_hourly_transactions();' 
AS request_query
)

SELECT
  livequery.live.udf_api(
    'POST',
    'https://science.flipsidecrypto.xyz/pro_access/submit_snowflake',
    { 'Content-Type': 'application/json' },
     { 
      'query' : request_query, 
      'server' : '{snowflake_url}',
      'user' : '{snowflake_username}',
      'pass' : '{snowflake_password}',
      'role' : '{snowflake_role}',
      'warehouse' : 'PRO',
      'database' : '{snowflake_database}'
    },
'charlie_pro'
  ) as first_row_json
from body

/*
-- Returns 1 just to test the API works 
SELECT
  livequery.live.udf_api(
    'GET', -- GET runs the test 
    'https://science.flipsidecrypto.xyz/pro_access/test_returns_1', -- Your API endpoint
      {}, -- empty header doesnt matter
      {}, -- empty data doesn't matter in GET
-- ''
 'charlie_pro'
  ) AS result

*/


```