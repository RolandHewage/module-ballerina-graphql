// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

# Represents any error related to the Ballerina GraphQL module.
public type Error distinct error;

# Represents the authentication error type.
public type AuthnError distinct Error;

# Represents the authorization error type.
public type AuthzError distinct Error;

// GraphQL client related errors representation

# Represents GraphQL client related generic errors.
public type GError ClientError|ServerError;

# Represents GraphQL client side or network level errors.
public type ClientError distinct error<record {| anydata body?; |}>;

# Represents GraphQL API response during GraphQL API server side errors.
public type ServerError distinct error<record {| json? data?; GraphQLError[] errors; map<json>? extensions?; |}>;

# Represents a list of GraphQL API server side errors.
public type GraphQLErrorArray GraphQLError[];
 
# Represents a GraphQL API server side error.
#
# + message - A string description of the error
# + locations - A list of locations in the requested GraphQL document associated with the error
# + path - A particular field in the GraphQL result associated with the error
# + extensions - Additional information to errors
public type GraphQLError record {
   string message;
   GraphQLSourceLocation[] locations?;
   anydata[] path?;
   map<anydata> extensions?;
};
 
# Represents a location in the requested GraphQL document associated with the error.
#
# + line - A line number starting from 1 which describe the beginning of an associated syntax element
# + column - A column number starting from 1 which describe the beginning of an associated syntax element
public type GraphQLSourceLocation record {
   int line?;
   int column?;
};
