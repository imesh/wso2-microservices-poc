import ballerina.net.http;
import ballerina.lang.messages;
import ballerina.lang.jsons;
import ballerina.lang.system;


@http:configuration {basePath:"/"}
service<http> loanApplicationsService {

    string loansServiceUrl = system:getEnv("LOANS_SERVICE_URL");
    string customersServiceUrl = system:getEnv("CUSTOMERS_SERVICE_URL");
    string creditsServiceUrl = system:getEnv("CREDITS_SERVICE_URL");

    @http:resourceConfig {
        methods:["POST"],
        path:"/"
    }
    resource createResource (message m) {

        json jsonMsg = messages:getJsonPayload(m);
        system:println("HTTP POST / resource invoked: " + jsons:toString(jsonMsg));

        http:ClientConnector customerserviceEP = create http:ClientConnector (customersServiceUrl);
        http:ClientConnector creditserviceEP = create http:ClientConnector (creditsServiceUrl);
        http:ClientConnector loanserviceEP = create http:ClientConnector (loansServiceUrl);

        string customerId;
        float income;
        float percentage = 40;
        float loanamount;
        float amounteligible;
        float outstandingbalance;

        customerId, _ = (string)jsonMsg["customerId"];
        income, _ = (float)jsonMsg["income"];
        loanamount, _ = (float)jsonMsg["amount"];

        message response = {};
        system:println("Invoking HTTP GET " + customersServiceUrl + "/" + customerId);
        response = customerserviceEP.get("/" + customerId, m);
        int statusCode = http:getStatusCode(response);
        if(statusCode != 200){
            system:println("Could not find a customer with id " + customerId + ", HTTP status code: " + statusCode);
            reply response;
        }
        system:println("Valid customer found with customer id " + customerId);

        system:println("Invoking HTTP GET " + creditsServiceUrl + "/" + customerId);
        response = creditserviceEP.get("/" + customerId, m);
        statusCode = http:getStatusCode(response);
        if(statusCode != 200){
            system:println("Error occurred while checking credit balance, HTTP status code: " + statusCode);
            reply response;
        }
        system:println("Valid credit records found");

        json jsonResponse = messages:getJsonPayload(response);
        outstandingbalance, _ = (float)jsonResponse["outstandingbalance"];
        amounteligible = ((income-outstandingbalance) * percentage) / 100;

        system:println("Outstanding balance: " + outstandingbalance);
        system:println("Amount elligible for the loan: " + amounteligible);
        if(loanamount  > amounteligible){
            messages:setStringPayload(response, "Customer is not elligible to get that amount " + loanamount);
            http:setStatusCode(response, 403);
            reply response;
        }

        system:println("Customer is elligible for the loan");
        response = loanserviceEP.post("/", m);
        system:println("Loan application created successfully");
        reply response;

    }

    @http:resourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource getAllResource (message m) {

        system:println("HTTP GET / resource invoked");
        http:ClientConnector loanserviceEP = create http:ClientConnector (loansServiceUrl);
        message response = {};
        system:println("Invoking HTTP GET " + loansServiceUrl + "/");
        response = loanserviceEP.get("/", m);
        reply response;
    }

    @http:resourceConfig {
        methods:["GET"],
        path:"/status/{referenceNumber}"
    }
    resource statusResource (message m, @http:PathParam {value:"referenceNumber"} string referenceNumber) {

        system:println("HTTP GET /status/{referenceNumber} resource invoked: [referenceNumber] " + referenceNumber);
        http:ClientConnector loanserviceEP = create http:ClientConnector (loansServiceUrl);
        message response = {};
        system:println("Invoking HTTP GET " + loansServiceUrl + "/status/" + referenceNumber);
        response = loanserviceEP.get("/status/" + referenceNumber, m);
        reply response;
    }

    @http:resourceConfig {
        methods:["POST"],
        path:"/approve/{referenceNumber}"
    }
    resource approveResource (message m, @http:PathParam {value:"referenceNumber"} string referenceNumber) {

        system:println("HTTP POST /approve/{referenceNumber} resource invoked: [referenceNumber] " + referenceNumber);
        http:ClientConnector loanserviceEP = create http:ClientConnector (loansServiceUrl);

        message response = {};
        system:println("Invoking HTTP POST " + loansServiceUrl + "/approve/" + referenceNumber);
        response = loanserviceEP.post("/approve/" + referenceNumber, m);
        reply response;
    }

    @http:resourceConfig {
        methods:["POST"],
        path:"/reject/{referenceNumber}"
    }
    resource rejectResource (message m, @http:PathParam {value:"referenceNumber"} string referenceNumber) {

        system:println("HTTP POST /reject/{referenceNumber} resource invoked: [referenceNumber] " + referenceNumber);
        http:ClientConnector loanserviceEP = create http:ClientConnector (loansServiceUrl);

        message response = {};
        system:println("Invoking HTTP POST " + loansServiceUrl + "/reject/" + referenceNumber);
        response = loanserviceEP.post("/reject/" + referenceNumber, m);
        reply response;
    }
}

