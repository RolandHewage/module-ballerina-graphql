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

import ballerina/test;
// import ballerina/io;

@test:Config {
    groups: ["client"]
}
function testExecuteWithSimpleVariable() returns error? {
    // GraphQL API URL
    string url = "https://countries.trevorblades.com/";
    // Query
    string query = string `query countryByCode($code:ID!) {country(code:$code) {name}}`;
    // Variables
    string code = "LK";
    map<anydata> variables = {"code": code};

    Client graphqlClient = check new (url);
    CountryByCodeResponse actualPayload = check graphqlClient->execute(query, variables);
    string actual = actualPayload.toJsonString();

    CountryByCodeResponse expectedPayload = {
        country: {
            name: "Sri Lanka"
        }
    };
    string expected = expectedPayload.toJsonString();

    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["client"]
}
function testExecuteWithComplexVariable() returns error? {
    // GraphQL API URL
    string url = "https://countries.trevorblades.com/";
    // Query
    string query = string `query countriesWithContinent($filter:CountryFilterInput) 
                          {countries(filter:$filter) {name continent {name}}}`;
    // Variables
    StringQueryOperatorInput stringQueryOperatorInput = {
        eq: "LK"
    };
    CountryFilterInput filter = {
        code: stringQueryOperatorInput
    };
    map<anydata> variables = {"filter": filter};

    Client graphqlClient = check new (url);
    CountriesWithContinentResponse actualPayload = check graphqlClient->execute(query, variables);
    string actual = actualPayload.toJsonString();

    CountriesWithContinentResponse expectedPayload = {
        countries: [{
            name: "Sri Lanka",
            continent: {name: "Asia"}
        }]
    };
    string expected = expectedPayload.toJsonString();

    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["client"]
}
function testExecuteWithMultipleVariables() returns error? {
    // GraphQL API URL
    string url = "https://countries.trevorblades.com/";
    // Query
    string query = string `query countryAndCountries($code:ID!, $filter:CountryFilterInput) 
                          {country(code:$code) {name} countries(filter:$filter) {name continent {name}}}`;
    // Variables
    string code = "LK";
    StringQueryOperatorInput stringQueryOperatorInput = {
        eq: "LK"
    };
    CountryFilterInput filter = {
        code: stringQueryOperatorInput
    };
    map<anydata> variables = {"filter": filter, "code": code};

    Client graphqlClient = check new (url);
    CountryAndCountriesResponse actualPayload = check graphqlClient->execute(query, variables);
    string actual = actualPayload.toJsonString();

    CountryAndCountriesResponse expectedPayload = {
        country: {
            name: "Sri Lanka"
        },
        countries: [{
            name: "Sri Lanka",
            continent: {name: "Asia"}
        }]
    };
    string expected = expectedPayload.toJsonString();

    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["client"]
}
function testExecuteWithoutVariables() returns error? {
    // GraphQL API URL
    string url = "https://countries.trevorblades.com/";
    // Query
    string query = string `query countryByLkCode {country(code:"LK") {name}}`;
    // Variables
    string code = "LK";
    map<anydata> variables = {"code": code};

    Client graphqlClient = check new (url);
    CountryByLkCodeResponse actualPayload = check graphqlClient->execute(query, variables);
    string actual = actualPayload.toJsonString();

    CountryByLkCodeResponse expectedPayload = {
        country: {
            name: "Sri Lanka"
        }
    };
    string expected = expectedPayload.toJsonString();

    test:assertEquals(actual, expected);
}

@test:Config {
    groups: ["client"]
}
function testExecuteWithMutation() returns error? {
    // GraphQL API URL
    string url = "https://api.spacex.land/graphql";
    // Query
    string query = string `mutation insertUser($objects:[users_insert_input!]!) 
                          {insert_users(objects:$objects) {affected_rows}}`;
    // Variables
    users_insert_input[] objects = [{name: "James"}];
    map<anydata> variables = {"objects": objects};

    Client graphqlClient = check new (url);
    InsertUserResponse actualPayload = check graphqlClient->execute(query, variables);
    string actual = actualPayload.toJsonString();

    InsertUserResponse expectedPayload = {
        insert_users: {
            affected_rows: 1
        }
    };
    string expected = expectedPayload.toJsonString();

    test:assertEquals(actual, expected);
}

# Represents ContinentFilterInput
public type ContinentFilterInput record {
    StringQueryOperatorInput? code?;
};

# Represents CountryFilterInput
public type CountryFilterInput record {
    StringQueryOperatorInput? continent?;
    StringQueryOperatorInput? code?;
    StringQueryOperatorInput? currency?;
};

# Represents LanguageFilterInput
public type LanguageFilterInput record {
    StringQueryOperatorInput? code?;
};

# Represents StringQueryOperatorInput
public type StringQueryOperatorInput record {
    string?[]? nin?;
    string? regex?;
    string? ne?;
    string? glob?;
    string? eq?;
    string?[]? 'in?;
};

# Represents CountryByCodeResponse
type CountryByCodeResponse record {|
    map<json?> __extensions?;
    record {|
        string name;
    |}? country;
|};

# Represents CountriesWithContinentResponse
type CountriesWithContinentResponse record {|
    map<json?> __extensions?;
    record {|
        string name;
        record {|
            string name;
        |} continent;
    |}[] countries;
|};

# Represents CountryAndCountriesResponse
type CountryAndCountriesResponse record {|
    map<json?> __extensions?;
    record {|
        string name;
    |}? country;
    record {|
        string name;
        record {|
            string name;
        |} continent;
    |}[] countries;
|};

# Represents CountryByLkCodeResponse
type CountryByLkCodeResponse record {|
    map<json?> __extensions?;
    record {|
        string name;
    |}? country;
|};

# Represents users_insert_input
public type users_insert_input record {
    string? twitter?;
    string? rocket?;
    string? name?;
    anydata? id?;
    anydata? timestamp?;
};

# Represents InsertUserResponse
type InsertUserResponse record {|
    map<json?> __extensions?;
    record {|
        int affected_rows;
    |}? insert_users;
|};
