import ballerina/graphql;
import ballerina/http;

// Create an `http:Listener`
http:Listener httpListener = new(9090);

// The `graphql:Service` exposes a GraphQL service on provided HTTP listener
service graphql:Service /graphql on new graphql:Listener(httpListener) {

    // This resolver returns a `Person` object. Each field of the Person object
    // can be queried by a GraphQL client
    resource function get profile(int id) returns Person {

        return people[id];
    }
}

// Define custom record types to return data
public type Address record {
    string number;
    string street;
    string city;
};
public type Person record {
    string name;
    int age;
    Address address;
};

// Define an array of `Person` records
Person p1 = {
    name: "Sherlock Holmes",
    age: 40,
    address: {
        number: "221/B",
        street: "Baker Street",
        city: "London"
    }
};

Person p2 = {
    name: "Walter White",
    age: 50,
    address: {
        number: "308",
        street: "Negra Arroyo Lane",
        city: "Albuquerque"
    }
};

Person p3 = {
    name: "Tom Marvolo Riddle",
    age: 100,
    address: {
        number: "Uknown",
        street: "Unknown",
        city: "Hogwarts"
    }
};

Person[] people = [p1, p2, p3];