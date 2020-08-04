## -----------------------------------------------------------------------------
library(httr)
library(jsonlite)


## -----------------------------------------------------------------------------
gen3token=fromJSON("credentials.json")
url="https://gen3.theanvil.io/user/credentials/cdis/access_token"


## -----------------------------------------------------------------------------
bearertokendata=POST(url,body=gen3token, encode="json")
bearertoken=as.character(fromJSON(content(bearertokendata,"text"))$access_token)


## -----------------------------------------------------------------------------
query = '{"query":"{project(first:0){project_id id}}"}';


## -----------------------------------------------------------------------------
url2="https://gen3.theanvil.io/api/v0/submission/graphql/"
result=POST(url2, body=query, encode="json",httr::add_headers(Authorization=paste("Bearer",bearertoken)))

fromJSON(content(result,"text"))


## -----------------------------------------------------------------------------
query = '{"query":"{__schema {types {name}}}"}';
result=POST(url2, body=query, encode="json",httr::add_headers(Authorization=paste("Bearer",bearertoken)))
fromJSON(content(result,"text"))



## -----------------------------------------------------------------------------
myl=list(query='{__type(name: "subject") {name fields{name}}}')
query=toJSON(myl,auto_unbox=TRUE)
result=POST(url2, body=query, encode="json",httr::add_headers(Authorization=paste("Bearer",bearertoken)))
fromJSON(content(result,"text"))


## -----------------------------------------------------------------------------
myl=list(query='{
  subject(first:10) {
    id
    project_id
    affected_status
  }
}')
query=toJSON(myl,auto_unbox=TRUE)
result=POST(url2, body=query, encode="json",httr::add_headers(Authorization=paste("Bearer",bearertoken)))
fromJSON(content(result,"text"))


## -----------------------------------------------------------------------------
myl=list(query='{__type(name: "sample") {name fields{name}}}')
query=toJSON(myl,auto_unbox=TRUE)
result=POST(url2, body=query, encode="json",httr::add_headers(Authorization=paste("Bearer",bearertoken)))
fromJSON(content(result,"text"))


## -----------------------------------------------------------------------------
myl=list(query='{
  sample(first:10) {
    id
    rin_number
  }
}')
query=toJSON(myl,auto_unbox=TRUE)
result=POST(url2, body=query, encode="json",httr::add_headers(Authorization=paste("Bearer",bearertoken)))
fromJSON(content(result,"text"))


## -----------------------------------------------------------------------------
myl=list(query='{__type(name: "sequencing") {name fields{name}}}')
query=toJSON(myl,auto_unbox=TRUE)
result=POST(url2, body=query, encode="json",httr::add_headers(Authorization=paste("Bearer",bearertoken)))
fromJSON(content(result,"text"))


## -----------------------------------------------------------------------------
myl=list(query='{sequencing{id file_name}}')
query=toJSON(myl,auto_unbox=TRUE)
result=POST(url2, body=query, encode="json",httr::add_headers(Authorization=paste("Bearer",bearertoken)))
fromJSON(content(result,"text"))


## -----------------------------------------------------------------------------
myl=list(query='{
  subject(first:10,project_id:"open_access-1000Genomes") {
    id
    project_id
    sex
  }
}')
query=toJSON(myl,auto_unbox=TRUE)
result=POST(url2, body=query, encode="json",httr::add_headers(Authorization=paste("Bearer",bearertoken)))
fromJSON(content(result,"text"))

