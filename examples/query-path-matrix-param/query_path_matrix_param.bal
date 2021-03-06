import ballerina/http;
import ballerina/log;

service /sample on new http:Listener(9090) {

    // The `PathParam` and `QueryParam` parameters extract values from the request URI.
    // Path param is defined as a part of the resource path along with the type.
    resource function get path/[string foo](http:Caller caller,
                                            http:Request req) {
        // Get the [QueryParam](https://ballerina.io/learn/api-docs/ballerina/#/ballerina/http/latest/http/classes/Request#getQueryParamValue)
        // value for a given parameter key.
        var bar = req.getQueryParamValue("bar");

        // Get the [MatrixParams](https://ballerina.io/learn/api-docs/ballerina/#/ballerina/http/latest/http/classes/Request#getMatrixParams).
        map<any> pathMParams = req.getMatrixParams("/sample/path");
        var a = <string>pathMParams["a"];
        var b = <string>pathMParams["b"];
        string pathMatrixStr = string `a=${a}, b=${b}`;
        map<any> fooMParams = req.getMatrixParams("/sample/path/" + foo);
        var x = <string>fooMParams["x"];
        var y = <string>fooMParams["y"];
        string fooMatrixStr = string `x=${x}, y=${y}`;
        json matrixJson = {"path": pathMatrixStr, "foo": fooMatrixStr};

        // Create a JSON payload with the extracted values.
        json responseJson = {
            "pathParam": foo,
            "queryParam": bar,
            "matrix": matrixJson
        };
        http:Response res = new;
        // A util method to set the JSON payload to the response message.
        res.setJsonPayload(<@untainted>responseJson);
        // Send a response to the client.
        var result = caller->respond(res);

        if (result is error) {
            log:printError("Error when responding", err = result);
        }
    }
}
