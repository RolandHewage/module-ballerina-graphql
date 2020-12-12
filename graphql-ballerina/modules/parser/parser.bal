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

public class Parser {
    private Lexer lexer;
    private DocumentNode document;

    public isolated function init(string text) {
        self.lexer = new(text);
        self.document = new;
    }

    public isolated function parse() returns DocumentNode|Error {
        check self.populateDocument();
        return self.document;
    }

    isolated function populateDocument() returns Error? {
        Token token = check self.peekNextNonSeparatorToken();

        while (token.kind != T_EOF) {
            check self.parseRootOperation(token);
            token = check self.peekNextNonSeparatorToken();
        }
    }

    isolated function parseRootOperation(Token token) returns Error? {
        if (token.kind == T_OPEN_BRACE) {
            return self.parseAnonymousOperation();
        } else if (token.kind == T_TEXT) {
            Scalar value = token.value;
            if (value is RootOperationType) {
                return self.parseOperationWithType(value);
            }
        }
        return getUnexpectedTokenError(token);
    }

    isolated function parseAnonymousOperation() returns Error? {
        Token token = check self.peekNextNonSeparatorToken();
        OperationNode operation = check self.createOperationRecord(ANONYMOUS_OPERATION, QUERY, token.location);
        self.addOperationToDocument(operation);
    }

    isolated function parseOperationWithType(RootOperationType operationType) returns Error? {
        Token token = check self.readNextNonSeparatorToken();
        Location location = token.location.clone();
        token = check self.peekNextNonSeparatorToken();
        string operationName = check getOperationNameFromToken(self);

        token = check self.peekNextNonSeparatorToken();
        TokenType tokenType = token.kind;
        if (tokenType == T_OPEN_BRACE) {
            OperationNode operation = check self.createOperationRecord(operationName, operationType, location);
            self.addOperationToDocument(operation);
        } else {
            return getExpectedCharError(token, OPEN_BRACE);
        }
    }

    isolated function createOperationRecord(string name, RootOperationType kind, Location location)
    returns OperationNode|Error {
        OperationNode operation = new(name, kind, location);
        check self.addSelections(operation);
        return operation;
    }

    isolated function addSelections(ParentType parentNode) returns Error? {
        Token token = check self.readNextNonSeparatorToken(); // Read the open brace here
        while (token.kind != T_CLOSE_BRACE) {
            token = check self.readNextNonSeparatorToken();
            string name = check getStringTokenvalue(token);
            FieldNode fieldNode = new(name, token.location);
            token = check self.peekNextNonSeparatorToken();
            if (token.kind == T_OPEN_PARENTHESES) {
                check self.addArgumentsToSelection(fieldNode);
            }

            token = check self.peekNextNonSeparatorToken();
            if (token.kind == T_OPEN_BRACE) {
                check self.addSelections(fieldNode);
            }
            parentNode.addSelection(fieldNode);
            token = check self.peekNextNonSeparatorToken();
        }
        // If it comes to this, token.kind == T_CLOSE_BRACE. We consume it
        token = check self.readNextNonSeparatorToken();
    }

    isolated function addArgumentsToSelection(FieldNode fieldNode) returns Error? {
        Token token = check self.readNextNonSeparatorToken(); // Reading the open parentheses
        while (token.kind != T_CLOSE_PARENTHESES) {
            token = check self.readNextNonSeparatorToken();
            ArgumentName name = check getArgumentName(token);

            token = check self.readNextNonSeparatorToken();
            if (token.kind != T_COLON) {
                return getExpectedCharError(token, COLON);
            }

            token = check self.readNextNonSeparatorToken();
            ArgumentValue value = check getArgumentValue(token);

            ArgumentNode argument = new(name, value, <ArgumentType>token.kind);
            fieldNode.addArgument(argument);
            token = check self.peekNextNonSeparatorToken();
        }
        // If it comes to this, token.kind == T_CLOSE_BRACE. We consume it
        token = check self.readNextNonSeparatorToken();
    }

    isolated function addOperationToDocument(OperationNode operation) {
        self.document.addOperation(operation);
    }

    isolated function readNextNonSeparatorToken() returns Token|Error {
        Token token = check self.lexer.read();
        if (token.kind is IgnoreType) {
            return self.readNextNonSeparatorToken();
        }
        return token;
    }

    isolated function peekNextNonSeparatorToken() returns Token|Error {
        int i = 1;
        Token token = check self.lexer.peek(i);
        while (true) {
            if (token.kind is LexicalType) {
                break;
            }
            i += 1;
            token = check self.lexer.peek(i);
        }

        return token;
    }
}

isolated function getRootOperationType(Token token) returns RootOperationType|Error {
    string value = <string>token.value;
    if (value is RootOperationType) {
        return value;
    }
    return getUnexpectedTokenError(token);
}

isolated function getArgumentName(Token token) returns ArgumentName|Error {
    if (token.kind == T_TEXT) {
        return {
            value: <string>token.value,
            location: token.location
        };
    } else {
        return getExpectedNameError(token);
    }
}

isolated function getArgumentValue(Token token) returns ArgumentValue|Error {
    if (token.kind is ArgumentType) {
        return {
            value: token.value,
            location: token.location
        };
    } else {
        return getUnexpectedTokenError(token);
    }
}

isolated function getOperationNameFromToken(Parser parser) returns string|Error {
    Token token = check parser.peekNextNonSeparatorToken();
    if (token.kind == T_TEXT) {
        // If this is a named operation, we should consume name token
        token = check parser.readNextNonSeparatorToken();
        return <string>token.value;
    } else if (token.kind == T_OPEN_BRACE) {
        return ANONYMOUS_OPERATION;
    }
    return getUnexpectedTokenError(token);
}

isolated function getStringTokenvalue(Token token) returns string|Error {
    if (token.kind == T_TEXT) {
        return <string>token.value;
    } else {
        return getExpectedNameError(token);
    }
}
