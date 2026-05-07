public with sharing class OpenAIWebSearchAction {
    
    // Input class for Flow: collects the API key and the user’s search query.
    public class OpenAIWebSearchInput {
        @InvocableVariable(label='OpenAI API Key' required=true)
        public String apiKey;
        
        @InvocableVariable(label='Search Query' required=true)
        public String searchQuery;
    }
    
    // Output class for Flow: returns the text portion of the response
    // plus the entire JSON response (for logging or troubleshooting).
    public class OpenAIWebSearchOutput {
        @InvocableVariable(label='Response Text')
        public String responseText;
        
        @InvocableVariable(label='Full JSON Response')
        public String fullJsonResponse;
    }
    
    @InvocableMethod(
        label='Call OpenAI Web Search' 
        description='Calls the OpenAI Web Search endpoint with the provided API key and search query.'
    )
    public static List<OpenAIWebSearchOutput> callOpenAIWebSearch(List<OpenAIWebSearchInput> inputList) {
        
        // Validate that we have at least one record.
        if(inputList == null || inputList.isEmpty()) {
            throw new IllegalArgumentException('No input provided to OpenAIWebSearchAction.');
        }
        
        // We’ll only process the first record for simplicity.
        OpenAIWebSearchInput input = inputList[0];
        
        // Construct the HTTP request to the OpenAI /v1/responses endpoint.
        String endpoint = 'https://api.openai.com/v1/responses';
        
        // Build the JSON body as shown in your sample request:
        // {
        //   "model": "gpt-4o",
        //   "tools": [{"type": "web_search"}],
        //   "input": "<user's search query>"
        // }
        Map<String, Object> requestBody = new Map<String, Object>{
            'model' => 'gpt-4o',
            'tools' => new List<Object>{ new Map<String, Object>{ 'type' => 'web_search' } },
            'input' => input.searchQuery
        };
        
        // Serialize the body to JSON.
        String body = JSON.serialize(requestBody);
        
        // Prepare the HTTP request.
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        
        // OpenAI expects a Bearer token in the Authorization header.
        // This is the user-provided API key.
        req.setHeader('Authorization', 'Bearer ' + input.apiKey);
        req.setHeader('Content-Type', 'application/json');
        
        // Attach the request body.
        req.setBody(body);
        
        // You can optionally set a higher timeout if you expect longer processing.
        req.setTimeout(120000); // 120 seconds
        
        Http http = new Http();
        OpenAIWebSearchOutput output = new OpenAIWebSearchOutput();
        
        try {
            // Make the callout.
            HttpResponse res = http.send(req);
            
            // Check for success (HTTP 200).
            if(res.getStatusCode() == 200) {
                // Parse the JSON response.
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                // Store the full JSON for debugging or logs.
                output.fullJsonResponse = res.getBody();
                
                // Attempt to extract the “message” text from the "output" array.
                if(jsonResponse.containsKey('output')) {
                    List<Object> outputList = (List<Object>) jsonResponse.get('output');
                    if(outputList != null && outputList.size() > 1) {
                        
                        // The second item is typically the “message” object with user-facing text.
                        Map<String, Object> messageObj = (Map<String, Object>) outputList[1];
                        
                        // Confirm it has "content" array.
                        if(messageObj.containsKey('content')) {
                            List<Object> contentArray = (List<Object>) messageObj.get('content');
                            
                            if(contentArray != null && !contentArray.isEmpty()) {
                                // Each content item can have a "text" field, among others.
                                Map<String, Object> firstContent = (Map<String, Object>) contentArray[0];
                                if(firstContent.containsKey('text')) {
                                    output.responseText = (String) firstContent.get('text');
                                }
                            }
                        }
                    }
                }
                
                // If parsing fails or structure is unexpected, responseText might remain null/blank.
                // You could add more robust checks as needed.
                
            } else {
                // Non-200 response: capture status code and entire response for clarity.
                output.responseText = 'Error: ' + res.getStatusCode() + ' ' + res.getStatus();
                output.fullJsonResponse = res.getBody();
            }
            
        } catch(Exception ex) {
            // Capture the exception details in the output.
            output.responseText = 'Exception: ' + ex.getMessage();
            output.fullJsonResponse = 'No response body due to exception.';
        }
        
        // Return a single record back to the Flow.
        return new List<OpenAIWebSearchOutput>{ output };
    }
}