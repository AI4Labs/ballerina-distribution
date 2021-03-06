import ballerina/test;

(any|error)[] outputs = [];

// This is the mock function which will replace the real function
@test:Mock {
    moduleName: "ballerina/io",
    functionName: "println"
}
test:MockFunction mock_printLn = new();

public function mockPrint(any|error... s) {
    foreach var entry in s {
        outputs.push(entry);
    }
}

@test:Config {}
function testFunc() {
    test:when(mock_printLn).call("mockPrint");

    // Invoking the main function
    main();
    map<anydata> mp1 = { info: "Detail Info", fatal: true };
    test:assertEquals(outputs[0], "Reason String: Sample Error");
    test:assertEquals(outputs[1], "Info: ");
    test:assertEquals(outputs[2], "Detail Info");
    test:assertEquals(outputs[3], "Fatal: ");
    test:assertEquals(outputs[4], true);
    test:assertEquals(outputs[5], "Reason String: ");
    test:assertEquals(outputs[6], "Sample Error");
    test:assertEquals(outputs[7], "Detail Map: ");
    test:assertEquals(outputs[8], mp1);
    test:assertEquals(outputs[9], "Detail Message: ");
    test:assertEquals(outputs[10], "Failed Message");

}
