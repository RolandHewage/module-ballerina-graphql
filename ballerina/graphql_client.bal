// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/jballerina.java;
import ballerina/http;
 
# The [Ballerina](https://ballerina.io/) generic client for GraphQL(https://graphql.org/) APIs.
public isolated client class Client {
   final http:Client clientEp;

   # Gets invoked to initialize the `connector`.
   #
   # + serviceUrl - URL of the target service
   # + clientConfig - The configurations to be used when initializing the `connector`
   # + return - An error at the failure of client initialization
   public isolated function init(string serviceUrl, http:ClientConfiguration clientConfig = {})  returns GError? {
      do {
         http:Client httpEp = check new (serviceUrl, clientConfig);             
         self.clientEp = httpEp;
      } on fail var e {
         return error ClientError("GraphQL Client Error", e);
      }
      return;
   }

   # Executes a GraphQL query.
   #
   # + query - The GraphQL query. For example `query countryByCode($code:ID!) {country(code:$code) {name}}`.
   # + variables - The GraphQL variables. For example `{"code": "<variable_value>"}`.
   # + headers - The GraphQL API headers to execute each query 
   # + targetType - The payload (`record {}`), which is expected to be returned after data binding. For example 
   #               `type CountryByCodeResponse record {| map<json?> __extensions?; record{|string name;|}? country; |};`
   # + return - The payload (if the `targetType` is configured) or a `graphql:Error` if failed to execute the query
   remote isolated function execute(string query, map<anydata>? variables = (), map<string|string[]>? headers = (), 
                                    typedesc<record {}> targetType = <>) returns targetType|GError = @java:Method {
      'class: "io.ballerina.stdlib.graphql.client.QueryExecutor",
      name: "execute"
   } external;

   private isolated function executeQuery(typedesc<record {}> targetType, string query, 
                                         map<anydata>? variables, map<string|string[]>? headers) 
                                         returns record {}|GError {
      http:Request request = new;
      json graphqlPayload = getGraphqlPayload(query, variables);
      request.setPayload(graphqlPayload);

      json|http:ClientError httpResponse = self.clientEp->post("", request, headers = headers);

      do {
         if httpResponse is http:ClientError {
            if (httpResponse is http:ApplicationResponseError) {
               anydata data = check httpResponse.detail().get("body").ensureType(anydata);
               return error ClientError("GraphQL Client Error", body = data);
            }
            return error ClientError("GraphQL Client Error", httpResponse);
         } else {
            map<json> responseMap = <map<json>> httpResponse;

            if (responseMap.hasKey("errors")) {
               GraphQLError[] errors = check responseMap.get("errors").cloneWithType(GraphQLErrorArray);
               
               if (responseMap.hasKey("data") && !responseMap.hasKey("extensions")) {
                  return error ServerError("GraphQL Server Error", data = responseMap.get("data"), errors = errors);
               } else if (responseMap.hasKey("extensions") && !responseMap.hasKey("data")) {
                  map<json>? extensionsMap = 
                     (responseMap.get("extensions") is ()) ? () : <map<json>> responseMap.get("extensions");
                  return error ServerError("GraphQL Server Error", errors = errors, extensions = extensionsMap);
               } else if (responseMap.hasKey("data") && responseMap.hasKey("extensions")) {
                  map<json>? extensionsMap = 
                     (responseMap.get("extensions") is ()) ? () : <map<json>> responseMap.get("extensions") ;
                  return error ServerError("GraphQL Server Error", data = responseMap.get("data"), errors = errors, 
                     extensions = extensionsMap);
               } else {
                  return error ServerError("GraphQL Server Error", errors = errors);
               }
            } else {
               json responseData = responseMap.get("data");
               if (responseMap.hasKey("extensions")) {
                  responseData = check responseData.mergeJson({ "extensions" : responseMap.get("extensions") });
               }
               record {} response = check responseData.cloneWithType(targetType);
               return response;
            }
         }
      } on fail var e {
         return error ClientError("GraphQL Client Error", e);
      }
   }
}
 