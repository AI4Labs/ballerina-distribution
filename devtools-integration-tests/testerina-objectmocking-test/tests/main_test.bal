import ballerina/email;
import ballerina/http;
import ballerina/test;

// Mock object definition
public client class MockHttpClient {
    public string url = "http://mockUrl";

    public remote function get(@untainted string path, http:RequestMessage message = (), 
        http:TargetType targetType = http:Response) returns http:Response|http:ClientError {
            http:Response res = new;
            res.statusCode = 500;
            return res;
    }
}

@test:Config {}
function testUserDefinedMockObject() {

    clientEndpoint = <http:Client>test:mock(http:Client, new MockHttpClient());
    http:Response res = doGet();
    test:assertEquals(res.statusCode, 500);
    test:assertEquals(getClientUrl(), "http://mockUrl");
}

@test:Config {}
function testProvideAReturnValue() {

    http:Client mockHttpClient = <http:Client>test:mock(http:Client);
    http:Response mockResponse = new;
    mockResponse.statusCode = 500;

    test:prepare(mockHttpClient).when("get").thenReturn(mockResponse);
    clientEndpoint = mockHttpClient;
    http:Response res = doGet();
    test:assertEquals(res.statusCode, 500);
}

@test:Config {}
function testProvideAReturnValueBasedOnInput() {

    http:Client mockHttpClient = <http:Client>test:mock(http:Client);
    test:prepare(mockHttpClient).when("get").withArguments("/get?test=123", test:ANY).thenReturn(new http:Response());
    clientEndpoint = mockHttpClient;
    http:Response res = doGet();
    test:assertEquals(res.statusCode, 200);
}

@test:Config {}
function testProvideErrorAsReturnValue() {

    email:SmtpClient mockSmtpClient = <email:SmtpClient>test:mock(email:SmtpClient);
    smtpClient = mockSmtpClient;

    string[] emailIds = ["user1@test.com", "user2@test.com"];
    error? errMock = error("Email sending error", message = "email sending failed");
    test:prepare(mockSmtpClient).when("send").thenReturn(errMock);
    error? err = sendNotification(emailIds);
    test:assertTrue(err is error);
}

@test:Config {}
function testDoNothing() {

    email:SmtpClient mockSmtpClient = <email:SmtpClient>test:mock(email:SmtpClient);
    http:Response mockResponse = new;
    mockResponse.statusCode = 500;

    test:prepare(mockSmtpClient).when("send").doNothing();
    smtpClient = mockSmtpClient;

    string[] emailIds = ["user1@test.com", "user2@test.com"];
    error? err = sendNotification(emailIds);
    test:assertEquals(err, ());
}

@test:Config {}
function testMockMemberVarible() {
    string mockClientUrl = "http://foo";
    http:Client mockHttpClient = <http:Client>test:mock(http:Client);
    test:prepare(mockHttpClient).getMember("url").thenReturn(mockClientUrl);

    clientEndpoint = mockHttpClient;
    test:assertEquals(getClientUrl(), mockClientUrl);
}

@test:Config {}
function testProvideAReturnSequence() {
    http:Client mockHttpClient = <http:Client>test:mock(http:Client);
    http:Response mockResponse = new;
    mockResponse.statusCode = 500;

    test:prepare(mockHttpClient).when("get").thenReturnSequence(new http:Response(), mockResponse);
    clientEndpoint = mockHttpClient;
    http:Response res = doGetRepeat();
    test:assertEquals(res.statusCode, 500);
}

# VALIDATION CASES
# 1 - Validations for user defined mock object

public client class MockSmtpClientEmpty {
}

public client class MockSmtpClient {
    public remote function send(email:Email email) returns email:Error? {
    // do nothing
    }
}

public client class MockSmtpClientFuncErr {
    public remote function sendMail(email:Email email) returns email:Error? {
    // do nothing
    }
}

public client class MockSmtpClientSigErr {
    public remote function send(email:Email email) returns string {
        return "";
    }
}

public client class MockSmtpClientSigErr2 {
    public remote function send(string[] email) returns string {
        return "";
    }
}

public client class MockHttpClientSigErr {
    public remote function get(@untainted string path, any message = ()) returns http:Response|http:ClientError {
        http:Response res = new;
        res.statusCode = 500;
        return res;
    }
}

// 1.1) when the user-defined mock object is empty
@test:Config { }
function testEmptyUserDefinedObj() {
    email:SmtpClient|error mockSmtpClient = trap <email:SmtpClient>test:mock(email:SmtpClient, new MockSmtpClientEmpty());
    if (mockSmtpClient is error) {
        test:assertEquals(mockSmtpClient.message(), "mock object type 'MockSmtpClientEmpty' should have at least one member function or field declared.");
    } else {
        test:assertFail(msg = "Empty user defined object to mock not handled!");
    }
}


// 1.2) when user-defined object is passed to test:prepare function
@test:Config { }
function testUserDefinedMockRegisterCases() {
    email:SmtpClient mockSmtpClient = <email:SmtpClient>test:mock(email:SmtpClient, new MockSmtpClient());
    error? result = trap test:prepare(mockSmtpClient).when("send").doNothing();
    if (result is error) {
        test:assertEquals(result.message(), "cases cannot be registered to user-defined object type 'SmtpClient'");
    } else {
        test:assertFail(msg = "Invalid object for mock object not handled!");
    }
}

// 1.3) when the functions in mock is not available in the original
@test:Config { }
function testUserDefinedMockInvalidFunction() {
    email:SmtpClient|error mockSmtpClient = trap <email:SmtpClient>test:mock(email:SmtpClient, new MockSmtpClientFuncErr());
    if (mockSmtpClient is error) {
        test:assertEquals(mockSmtpClient.message(), "invalid function 'sendMail' provided");
    } else {
        test:assertFail(msg = "Missing function for mock object not handled!");
    }
}

// 1.4.1) when the function return types do not match
@test:Config { }
function testUserDefinedMockFunctionSignatureMismatch() {
    email:SmtpClient|error mockSmtpClient = trap <email:SmtpClient>test:mock(email:SmtpClient, new MockSmtpClientSigErr());
    if (mockSmtpClient is error) {
        test:assertEquals(mockSmtpClient.message(), "incompatible return type provided for function send()");
    } else {
        test:assertFail(msg = "Function signature mismatch for object not handled!");
    }
}

// 1.4.2) when the function parameters do not match
@test:Config { }
function testUserDefinedMockFunctionSignatureMismatch2() {
    email:SmtpClient|error mockSmtpClient = trap <email:SmtpClient>test:mock(email:SmtpClient, new MockSmtpClientSigErr2());
    if (mockSmtpClient is error) {
        test:assertEquals(mockSmtpClient.message(), "incompatible parameter type provided at position 1 in function send()");
    } else {
        test:assertFail(msg = "Function signature mismatch for object not handled!");
    }
}

// 1.4.3
@test:Config { }
function testUserDefinedMockFunctionSignatureMismatch3() {
    http:Client|error mockHttpClient = trap <http:Client>test:mock(http:Client, new MockHttpClientSigErr());
    if (mockHttpClient is error) {
        test:assertEquals(mockHttpClient.message(), "incorrect number of parameters provided for function get()");
    } else {
        test:assertFail(msg = "Function signature mismatch for object not handled!");
    }
}

# 2 - Validations for framework provided default mock object

// 2.1  when the function called in mock is not available in the original
@test:Config { }
function testDefaultMockInvalidFunctionName() {
    email:SmtpClient mockSmtpClient = <email:SmtpClient>test:mock(email:SmtpClient);
    error? result = trap test:prepare(mockSmtpClient).when("get").doNothing();
    if (result is error) {
        test:assertEquals(result.message(), "invalid function name 'get ' provided");
    } else {
        test:assertFail(msg = "Invalid function name for mock object not handled!");
    }
}

// 2.2) call doNothing() - the function has a return type specified
@test:Config { enable : false }
function testDefaultMockWrongAction() {
    http:Client mockHttpClient = <http:Client>test:mock(http:Client);
    error? result = trap test:prepare(mockHttpClient).when("get").doNothing();
    if (result is error) {
        test:assertEquals(result, "FunctionSignatureMismatchError");
    } else {
        test:assertFail(msg = "Wrong mock action for object not handled!");
    }
}

// 2.3) when the return value does not match the function return type
@test:Config { enable : false }
function testDefaultInvalidFunctionReturnValue() {
    http:Client mockHttpClient = <http:Client>test:mock(http:Client);
    error? result = trap test:prepare(mockHttpClient).when("get").thenReturn("success");
    if (result is error) {
        test:assertEquals(result, "FunctionSignatureMismatchError");
    } else {
        test:assertFail(msg = "Invalid function return value for mock object not handled!");
    }
}

// 2.4.1) when the number of arguments provided does not match the function signature
@test:Config { }
function testDefaultTooManyArgs() {
    http:Client mockHttpClient = <http:Client>test:mock(http:Client);
    error? result = trap test:prepare(mockHttpClient).when("get").withArguments("test", "", "").thenReturn(new http:Response());
    if (result is error) {
        test:assertEquals(result.message(), "incorrect type of argument provided at position '3' to mock the function get()");
    } else {
        test:assertFail(msg = "Too many arguments to mock object not handled!");
    }
}

// 2.4.2) when the type of arguments provided does not match the function signature
@test:Config { }
function testDefaultIncompatibleArgs() {
    http:Client mockHttpClient = <http:Client>test:mock(http:Client);
    error? result = trap test:prepare(mockHttpClient).when("get").withArguments(0).thenReturn(new http:Response());
    if (result is error) {
        test:assertEquals(result.message(), "incorrect type of argument provided at position '1' to mock the function get()");
    } else {
        test:assertFail(msg = "Incompatible arguments to mock object not handled!");
    }
}

// 2.5) when the object does not have a member variable of specified name
@test:Config { }
function testDefaultMockInvalidFieldName() {
    string mockClientUrl = "http://foo";
    http:Client mockHttpClient = <http:Client>test:mock(http:Client);
    error? result = trap test:prepare(mockHttpClient).getMember("clientUrl").thenReturn(mockClientUrl);
    if (result is error) {
        test:assertEquals(result.message(), "invalid field name 'clientUrl' provided");
    } else {
        test:assertFail(msg = "Invalid field name for mock object not handled!");
    }
}

// 2.6) when the member variable type does not match the return value
@test:Config { }
function testDefaultInvalidMemberReturnValue() {
    http:Client mockHttpClient = <http:Client>test:mock(http:Client);
    error? result = trap test:prepare(mockHttpClient).getMember("url").thenReturn(());
    if (result is error) {
        test:assertEquals(result.message(), "return value provided does not match the type of 'url'");
    } else {
        test:assertFail(msg = "Invalid member return value for mock object not handled!");
    }
}
