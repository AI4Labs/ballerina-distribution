import ballerina/http;
import ballerina/log;

// Create an endpoint with port 8080 for the mock backend services.
listener http:Listener backendEP = check new (8080);

// Define the load balance client endpoint to call the backend services.
http:LoadBalanceClient lbBackendEP = check new ({
        // Define the set of HTTP clients that need to be load balanced.
        targets: [
            {url: "http://localhost:8080/mock1"},
            {url: "http://localhost:8080/mock2"},
            {url: "http://localhost:8080/mock3"}
        ],

        timeoutInMillis: 5000
});

// Create an HTTP service bound to the endpoint (`loadBalancerEP`).
service /lb on new http:Listener(9090) {

    resource function 'default .(http:Caller caller, http:Request req) {
        json requestPayload = {"name": "Ballerina"};
        var response = lbBackendEP->post("/", requestPayload);
        // If a response is returned, the normal process runs. If the service
        // does not get the expected response, the error-handling logic is
        // executed.
        if (response is http:Response) {
            var responseToCaller = caller->respond(<@untainted>response);
            if (responseToCaller is http:ListenerError) {
                log:printError("Error sending response",
                                err = responseToCaller);
            }
        } else {
            http:Response outResponse = new;
            outResponse.statusCode = 500;
            outResponse.setPayload((<@untainted error>response).message());
            var responseToCaller = caller->respond(outResponse);
            if (responseToCaller is http:ListenerError) {
                log:printError("Error sending response",
                                err = responseToCaller);
            }
        }

    }
}

// Define the mock backend services, which are called by the load balancer.
service /mock1 on backendEP {

    resource function 'default .(http:Caller caller, http:Request req) {
        var responseToCaller = caller->respond("Mock1 resource was invoked.");
        if (responseToCaller is http:ListenerError) {
            handleRespondResult(responseToCaller);
        }
    }
}

service /mock2 on backendEP {

    resource function 'default .(http:Caller caller, http:Request req) {
        var responseToCaller = caller->respond("Mock2 resource was invoked.");
        if (responseToCaller is http:ListenerError) {
            handleRespondResult(responseToCaller);
        }
    }
}

service /mock3 on backendEP {

    resource function 'default .(http:Caller caller, http:Request req) {
        var responseToCaller = caller->respond("Mock3 resource was invoked.");
        if (responseToCaller is http:ListenerError) {
            handleRespondResult(responseToCaller);
        }
    }
}

// Function to handle respond results
function handleRespondResult(http:ListenerError? result) {
    if (result is http:ListenerError) {
        log:printError("Error sending response from mock service",
                        err = result);
    }
}
