postman.setGlobalVariable(
    "ptf", 
    () => { 
        let methods = {
            "testPtf": (msg = 'something') => {
                console.log(msg);
                console.log(pm.response);
                console.log(requestData);
            },
            "parseJwt": function(token) {
                var base64Url = token.split('.')[1];
                var base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
                var jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
                    return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
                }).join(''));

                return JSON.parse(jsonPayload);
            },
            "slugify": function(text) {
                return text
                .toString()
                .normalize( 'NFD' )                   // split an accented letter in the base letter and the acent
                .replace( /[\u0300-\u036f]/g, '' )   // remove all previously split accents
                .toLowerCase()
                .trim()
                .replace(/_/g, '-')
                .replace(/\s+/g, '-')
                .replace(/[^\w\-]+/g, '')
                .replace(/\-\-+/g, '-'); 
            },
            "getPreRequestData": () => {
                // Note: postman variables without quotes around them will break.
                let preRequest = pm.request.body;
                let curBodyData = _.get(preRequest, 'raw', "{}");
                return curBodyData ? JSON.parse(curBodyData) : {};
            },
            "setPreRequestData": (newData) => {
                let modifiedRequest = _.set(pm.request.body, 'raw', JSON.stringify({
                        ...ptf.getPreRequestData(),
                        ...newData
                    }));

                pm.request.body.update(modifiedRequest);
            },
            "triggerRequestReRuns": (endpointId, times = 1) => {
                let set_next_request = pm.globals.get("set_next_request") ? JSON.parse(pm.globals.get("set_next_request")) : {};
                
                if (_.has(set_next_request, ptf.slugify(endpoint.request_name))) {
                    set_next_request[ptf.slugify(endpoint.request_name)] -= 1;
                    if (set_next_request[ptf.slugify(endpoint.request_name)] > 0) {
                        console.log('trigger again..', endpointId);
                        postman.setNextRequest(endpointId);
                    } else {
                        console.log('deleting the record', endpointId);
                        delete set_next_request[ptf.slugify(endpoint.request_name)];
                        postman.setNextRequest();
                    }
                } else {
                    set_next_request[ptf.slugify(endpoint.request_name)] = times;
                    console.log('trigger - first time', endpointId);
                    postman.setNextRequest(endpointId);
                }

                pm.globals.set("set_next_request", JSON.stringify(set_next_request));
            },
            "alterRequestForExample": () => {
                let curPath = pm.request.url.getPath();

                let productPaths = [
                    '/api/some/path', // example
                ];

                // use this eventually, as needed
                // let exceptionPaths [];

                let pathMatch = false;

                for (let i = 0; i < productPaths.length; i++) {
                    
                    if (curPath.includes(productPaths[i])) {
                        pathMatch = true;        
                        break;
                    }
                }

                if (pathMatch) {
                    //ptf.setPreRequestData({"user_id": "{{some_var}}"});
                }

            },
            "getGlobal": (globalKey, globalJson = false) => {
                if (!pm.globals.has(globalKey)) {
                    return {};
                }
                return globalJson ? JSON.parse(pm.globals.get(globalKey)) : pm.globals.get(globalKey);
            },
            "setGlobal": (globalKey, globalData, globalJson = false) => {
                return pm.globals.set(globalKey, globalJson ? JSON.stringify(globalData) : globalData);
            },
            "runErrorResponseTest": () => {
                // this should be customized to how your api returns errors.
                pm.test("If client request errors, has correct structure for it", function(){
                    pm.expect(response).to.have.property('success');

                    // example of potential error pattern structure test:
                    if (!response.success) {
                        pm.expect(response).to.include.all.keys(
                            'status',
                            'error',
                            'errors'
                        )
                    }
                });
            },
            "runSuccessResponseTest": (endpointName = "Endpoint") => {
                pm.test( endpointName +  ": Success", function () {
                    pm.response.to.have.status(200);
                });
            },
            // After this point, you can make custom functions that may share a lot of the same code
            // For example, you may have pretty standard approach of testing endpoints that return options/lists.
            "runOptionsTest": (pm, request, response, requestData, endpoint, expectsQuery = false) => {

                // If any errors, it has correct format.
                ptf.runErrorResponseTest();

                let scope = _.get(request, 'headers.format');

                if (scope && scope.length) {
                    endpoint.name += ' - ' + scope;
                }

                // if this options list allows a query (eg. a typehead search term to find option)
                if (expectsQuery) {
                    pm.test("Request data includes query", function(){
                        pm.expect(requestData).to.have.property('query');
                    });
                }

                ptf.runSuccessResponseTest(endpoint.name);

                pm.test(endpoint.name + ": Basic Structure", function(){
                    pm.expect(response, 'Response missing ' + endpoint.key).to.have.property(endpoint.key);
                    let options = [];

                    // No scope, then will have applied_query
                    if (expectsQuery) {

                        // The options will be nested -  like accounts_options.options: [ {}, {} ]
                        pm.expect(response[endpoint.key], 
                        endpoint.name + ' is missing expected options property').to.be.an('object').and.to.have.property('options');
                        pm.expect(response[endpoint.key].options, 'Options is not an array').to.be.an('array');

                        options = response[endpoint.key].options;
                    } else {
                        if (endpoint.optionsKey) {
                            pm.expect(response[endpoint.key][endpoint.optionsKey], endpoint.name + ' is missing expected options property').to.be.an('array');
    
                            options = response[endpoint.key][endpoint.optionsKey];
                        } else {
                            // The options will be flat - directly in it like accounts_options: [ {}, {} ]
                            pm.expect(response[endpoint.key], endpoint.name + ' is missing expected options property').to.be.an('array');
    
                            options = response[endpoint.key];
                        }
                    }

                    // If we have items in the options array, check their structure is object and display value keys.
                    if (options.length) {
                        // Options in data_key have display, value
                        for (let i = 0; i < options.length; i++) {
                            pm.expect(options[i],
                            'An item [' + i + '] in the array is missing expected keys').to.be.an('object').and.to.include.all.keys(
                                'display',
                                'value'
                            );
                        }
                    }
                });
            },
        };
        return methods; 
    }
);