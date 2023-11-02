# PTF - Library Docs

This documentation will explain how to use postman as a **Test suite** for your API. It is in the spirit of end-to-end testing for the API endpoints themselves. It is suggested that you run them locally and/or against development or test environments. 

This library is about how to write the tests and get them setup in the Postman App. We will cover the structure, naming conventions, version controll, and setup of included javascript to create a "framework" for what you put in your Test Suite Collection.

🎗️ Before we get started, a little reminder:

- **Postman Tests & GUI**

    As you may know, Postman has a "Tests" tab in each request and can be ran from inside the postman UI. When you send a request with tests, there will be a test results tab in your response pane. Additionally, you can select a folder and run all the requests/tests in them consequetively. 

- **Postman Tests & CLI**

    Aside from running tests in the UI, you can also run them in CLI. Download and install via npm the `newman` package to run your tests from the command line, unlocking all sorts of automation potential. For example, you can hook them into github events (commit/push) or actions via workflows. The main [README.md](../README.md) file explains that setup in more detail.

## Contents

- [Introduction](#ptf---library-docs)
  - [Postman Tests & GUI](#postman-tests--gui)
  - [Postman Tests & CLI](#postman-tests--cli)
- [Getting Started](#getting-started)
  - [Start with a New Collection](#start-with-a-new-collection)
  - [Forks, Pull Requests, and Merges](#forks-pull-requests-and-merges)
- [Collection: Top Level](#collection-top-level)
  - [Collection: Pre-Request Tab](#collection-pre-request-tab)
  - [Collection: Tests Tab](#collection-tests-tab)
  - [Collection: Structure and Folder Naming Conventions](#collection-structure-and-folder-naming-conventions)
- [Installation of ptf.js](#installation-of-ptfjs)
  - [Use ptf in a Request](#use-ptf-in-a-request)
  - [Login Example Request](#login-example-request)
  - [Complicated Example Request](#complicated-example-request)
- [Reference: ptf.js Methods](#ptfjs-framework-methods)
 
## Start with a new collection

You may have a collection in Postman already for your project, but for this test suite, you will want to **create a new collection**. I call mine "Test". 

You need a new collection to house the tests because are ran in the order of how your folders and requests are arranged. Each folder may contain a group of requests (and their respective tests) that are related to each other. Therefore, entire organization of this collection is built around the process of running tests, and not like API documentation.

New Collection:

```
Test
```

### Forks, Pull Requests, and Merges

This new collection will be the "origin". Then, each member of your team should create a fork of this **Test collection** and add their own tests to it to be pull-requested and merged into the main Test collection. **Postman has all this version-control capability built in** to the app - so it's easy to do.

[↑ Contents](#contents)

---

## Collection: Top Level

The top level collection folder ("Test" in the example) is an important place to put an overarching pre-request scripts you want to include in all your requests, like setting a specific header for example. This top level collection is also a good place to put "token" handling in the "tests" tab, if you plan to be testing authenticated endpoints.


### Collection: Pre-Request Tab

Below is an example of header `X-Client-Url` that our example api (or WAF) will require. 
This is a good place to put it, so you don't have to add it to every request.

```javascript
/* Add Header: X-Client-Url
 * 
 * Automate adding X-Client-Url header based on platform_current env var.
 * If the X-Client-Url is set specifically on the endpoint, use that.
 */

var platform = pm.environment.get("platform_current");
var headers = pm.request.getHeaders(
        {enabled:true}
    );


if (!headers['X-Client-Url']) {
    pm.request.headers.add({ 
        key: "X-Client-Url",
        value: platform 
    });
}
```

[↑ Contents](#contents)

---

### Collection: Tests Tab

Below is an example of a test that will save the token and refresh token to environment variables.

```javascript
// Parse Response
try {
    var jsonData = JSON.parse(responseBody)
} catch(e){
    return;
}
// Save Token to Envionrment Var.   
if (jsonData && jsonData.token && jsonData.token.length) {
    postman.setEnvironmentVariable("token", jsonData.token);
}

// Save Refresh Token to Envionrment Var.
if (jsonData && jsonData.refresh_token && jsonData.refresh_token.length) {  
    postman.setEnvironmentVariable("refresh_token", jsonData.refresh_token);
}
```

[↑ Contents](#contents)

---

### Collection: Structure and Folder Naming Conventions

Using our example collection "Test", below I will show an example of the structure and naming convention system that I recommend. 

```php
// Collection Level
Test
    // Platform Level
    console
    app* ← 1 asterisk means there is a pre-request script
        // Role Level
        As Customer
            // Group Level
            Login** ← 2 asterisks means it is unique to this role
                // Request Level
                Login
            Settings
                // Request Level
                Get Settings
                Update Settings
                Delete Settings
        As Demo
        As Admin
```

Here's what's going on:

- **Collection Level**

    This is your collection folder. I call mine "Test".
    You put your collection level pre-request scripts and tests here.

- **Platform Level** 
    
    I put each _platform_ in its own folder. You may have one or you may have two. For example, I have two platforms in my example - an admin console and a user-facing app.

- **Role Level**

    I put each _role_ in its own folder. You may have one or you may have many. For example, I have three roles in my example - a customer, a demo user, and an admin. The tests will be different for each of these roles, even if most of the endpoints are the same (especially demo vs customer). The initial login request would be different.

- **Group Level**

    I put each _group_ of requests in its own folder. You will likely have a lot of group folders and maybe even sub group folders. As you develop tests, you can use the postman GUI to run specific folders, which makes grouping them smart. These could also have pre-requests scripts or unique aspects, so be sure to use an asterisk method to help others understand such nuances.

- **Request Level**

    At this level, we are no longer talking about folders. These are the **actual postman requests** that you write tests into. I tend to put the 2 asterisks indication on the folder wrapping the endpoint in hopes its more visible to other developers before they copy it to other roles, but you could also put it on the request itself.

- **1 asterisk**

    I use one asterisk (`*`) to **denote that there is a pre-request script present in the folder**. This is a good way to keep track of which folders have pre-request scripts since most do not.

    👉 At the "Platform Level", I include the [`ptf.js`](ptf.js) framework - and then I extend it with custom reusable test functions - to make it easier to write tests that are very similar to each other. 
    
    - For example, several endpoints may be "options" (or lists, such as users, states, products to choose from). Some may need a "query" string to grab stuff, some may not. The assertations you write may be so similar you could pass a few arguments to a function to take care of basic testing around them. 

- **2 asterisks**

    I will use 2 asterisks (`**`) to indicate that the test is unique and cannot be copied. This is useful for role-based test groups where some endpoints cannot be copied from one role to another, even if most can. For example, the login request is unique to each role.

[↑ Contents](#contents)

---

## Install PTF.js

Highly recommend reviewing the [setup structure of your Test collection](#collection-structure-and-folder-naming-conventions), since we will want to "install" the `ptf.js` framework in the "Platform Level" folder.

You simply copy and paste it into the "Pre-request Script" tab of the "Platform Level" folder.

This framework will add itself to the globals available in Postman, which can be viewed in your environment.

---

### Use ptf in a request

To use ptf in a request, let's make a role folder, a group folder, and a test request.

Example - States Options: Test Tab

```javascript
let response = pm.response.json();
let requestData = request.data && request.data.length ? JSON.parse(request.data) : null;

// Setup
let endpoint = {
    name: 'States - Options',
    key: 'states'
}

// Load ptf object
ptf = eval(pm.globals.get("ptf"))();

///////////////// DEFAULT

ptf.runOptionsTest(pm, request, response, requestData, endpoint);
```

What's going on here?

- **Get Response, Get Request** 

    What did we get back from the server? What did we send to the server? We need to know this to write tests.

- **Setup**

    We setup our "custom" variables for this **options** endpoint that we plan to send to a custom function on our ptf object. We know we have a lot of "options" endpoints that will be similar, so we can write a custom function to handle them.

- **Load ptf object**

    We evaluate pm.globals for 'ptf' to get the library out from being loaded in the Platform level pre-request script. 

- **Run Options Test**

    This is an example "custom" function you can extend on your ptf framework for this Platform. We left this particular function somewhat in tact so you can adapt it to your needs.

    You can also run a method called `testPtf` just to see that it works and is setup

    ```javascript

    // test Ptf is working
    ptf.testPtf();
    ```

[↑ Contents](#contents)

---

### Login Example Request

For fun, I've decided to share what a login request might look like. 

You will see that this test is very simple and it does not use the `ptf.js` framework. 

🎗️ Reminder that in the top-level collection, we may have utilized the pre-request script to set custom pre-requests requirements (eg. adding `X-Client-Url` header), and also used the tests tab to handle the storing of the token (when present in response) in an environment variable. That's a nice way of not having to repeat ourselves in each Role -> Login request, Refresh token request, etc.

Request Body: Customer Login _(Role Level = Customer)_

```jsonc
{
    "email": "user@example.com",
    "password": "{{password}}" // this password is a var in the environment
}
```

Tests Tab: Customer Login

```javascript
pm.test("Customer Login Successful & Has token", function () {
    pm.response.to.have.status(200);
    let response = pm.response.json();
    pm.expect(response).to.have.property('token');
});

pm.test("Token stored in Postman Env", function() {
    let response = pm.response.json();
    let curToken = pm.environment.get("token");
    pm.expect(curToken).to.equal(response.token);
});
```

Hopefully that is a helpful way to understand how to write tests for your API endpoints, with or without the `ptf.js` library itself.

[↑ Contents](#contents)

--- 

### Complicated Example Request

Here is an example of a more complicated request that uses the `ptf.js` framework.

The strategy here is to put the **default** or "generic" tests that `ptf.js` has methods provided or extended to handle basic asserts, and then add **custom** tests below that - where custom here indicates that they are specific to this endpoint.

Request Body: Update Settings _(Role Level = Customer)_

```jsonc
{
    "email": "{{email}}", // this email is a var in the environment
    "password": "{{password}}", // this password is a var in the environment
    "settings": {
        "notifications": {
            "email": true,
            "sms": false
        },
        "profile": {
            "name": "John Doe",
            "phone": "555-555-5555"
        }
    }
}
```

Tests Tab: Update Settings

```javascript
let response = pm.response.json();
let requestData = request.data && request.data.length ? JSON.parse(request.data) : null;

// Setup
let endpoint = {
    name: 'Update Settings',
    key: 'updateSettings'
}

// Load ptf object
ptf = eval(pm.globals.get("ptf"))();

///////////////// DEFAULT

ptf.runSuccessResponseTest(endpoint.name);

///////////////// CUSTOM

// Test Settings

pm.test("Settings - Notifications - Email", function () {
    pm.expect(response.settings.notifications.email).to.equal(requestData.settings.notifications.email);
});

pm.test("Settings - Notifications - SMS", function () {
    pm.expect(response.settings.notifications.sms).to.equal(requestData.settings.notifications.sms);
});

pm.test("Settings - Profile - Name", function () {
    pm.expect(response.settings.profile.name).to.equal(requestData.settings.profile.name);
});

pm.test("Settings - Profile - Phone", function () {
    pm.expect(response.settings.profile.phone).to.equal(requestData.settings.profile.phone);
});

// etc...

```

🎗️ Remember that some of your tests will be purposefully erroneous, to test that the API handles them predictably. In that case the assertation will **not** be "success" like this example, but instead an error. 

We recommend adjusting the provided method for error responses (`runErrorResponseTest`) to adapt to your own format for how errors are returned - and then you can use those as the "default" batch of tests to run first before executing the custom asserts.

[↑ Contents](#contents)

---

### PTF.js Framework methods

The `ptf.js` framework has a few methods that you can use to write tests. You can also extend it with your own methods. This is a very loose "framework" or more like an initial starting point that you can use to help write tests and avoid repetition. It is meant for you to customize and extend to your needs.

- [testPtf(msg = 'something')](#testptfmsg--something)
- [parseJwt(token)](#parsejwttoken)
- [slugify(text)](#slugifytext)
- [getPreRequestData()](#getprerequestdata)
- [setPreRequestData(newData)](#setprerequestdatanewdata)
- [triggerRequestReRuns(endpointId, times = 1)](#triggerrequestrerunsendpointid-times--1)
- [alterRequestForExample()](#alterrequestforexample)
- [getGlobal(globalKey, globalJson = false)](#getglobalglobalkey-globaljson--false)
- [setGlobal(globalKey, globalData, globalJson = false)](#setglobalglobalkey-globaldata-globaljson--false)
- [formatRequestQuery(string)](#formatrequestquerystring)
- [runErrorResponseTest()](#runerrorresponsetest)
- [runSuccessResponseTest(endpointName = "Endpoint")](#runsuccessresponsetestendpointname--endpoint)
- [runOptionsTest(pm, request, response, requestData, endpoint, expectsQuery = false)](#runoptionstestpm-request-response-requestdata-endpoint-expectsquery--false)


[↑ Contents](#contents)

---

1. ### testPtf(msg = 'something'):
   - Logs a message, the Postman response, and requestData.

1. ### parseJwt(token):
   - Parses a JWT token and returns the decoded payload.

1. ### slugify(text):
   - Converts a string into a URL-friendly slug by replacing spaces and special characters and lowercasing them. Eg. `Something cool` -> `something-cool`

1. ### getPreRequestData():
   - Retrieves data from the request's body, if available.
   
   **Note:** postman variables without quotes around them will break.

1. ### setPreRequestData(newData):
   - Sets data in the request's body by merging it with existing data.

1. ### triggerRequestReRuns(endpointId, times = 1):
   - Controls request reruns by setting the next request in Postman based on conditions and a specified number of times.

1. ### alterRequestForExample():
   - If path matches a certain set of defined paths, then alter the pre-request data perhaps. Uses for specific request needs. Adjust as needed.

1. ### getGlobal(globalKey, globalJson = false):
   - Retrieves a global variable's value, optionally parsing it as JSON.

1. ### setGlobal(globalKey, globalData, globalJson = false):
   - Sets a global variable with data, and optionally if json then stringify it for storage.

1. ### runErrorResponseTest():
    - Defines a test to check if the client request returns an error, including the error's structure. This should be adapted to your needs - as it is meant to recognize a consistency of how errors are returned and ensure that structure is maintained.

1. ### runSuccessResponseTest(endpointName = "Endpoint"):
    - Defines a test for a successful response with a specified endpoint name - it looks for a 200 status code.

1. ### runOptionsTest(pm, request, response, requestData, endpoint, expectsQuery = false):
    - A specialized method for testing options or lists, including error and success response tests, and structure checks. This serves as an example of how you might extend this framework with your own custom methods that help reduce repetition for similar requests and their tests.

[↑ Contents](#contents) | [↑ Methods](#ptfjs-framework-methods)