public with sharing class OpenAIWebSearchAction {
    private static final String ENDPOINT = 'callout:OpenAI_API/v1/responses';
    private static final Integer MAX_ATTEMPTS = 2;

    public class OpenAIWebSearchInput {
        @InvocableVariable(label='Search Query' required=true) public String searchQuery;
    }
    public class OpenAIWebSearchOutput {
        @InvocableVariable(label='Response Text') public String responseText;
        @InvocableVariable(label='Response Metadata') public String fullJsonResponse;
    }

    @InvocableMethod(label='Call OpenAI Web Search' description='Calls the OpenAI Responses API with web search enabled through the OpenAI_API named credential.')
    public static List<OpenAIWebSearchOutput> callOpenAIWebSearch(List<OpenAIWebSearchInput> inputList) {
        if (inputList == null || inputList.isEmpty()) {
            throw new IllegalArgumentException('No input provided to OpenAIWebSearchAction.');
        }
        List<OpenAIWebSearchOutput> outputs = new List<OpenAIWebSearchOutput>();
        for (OpenAIWebSearchInput input : inputList) {
            outputs.add(callOne(input));
        }
        return outputs;
    }

    private static OpenAIWebSearchOutput callOne(OpenAIWebSearchInput input) {
        OpenAIWebSearchOutput output = new OpenAIWebSearchOutput();
        try {
            if (input == null || String.isBlank(input.searchQuery)) {
                output.responseText = 'Error: Search query is required.';
                output.fullJsonResponse = '{}';
                return output;
            }
            Map<String, Object> requestBody = new Map<String, Object>{
                'model' => 'gpt-4o',
                'tools' => new List<Object>{ new Map<String, Object>{ 'type' => 'web_search' } },
                'input' => input.searchQuery
            };
            HttpRequest req = new HttpRequest();
            req.setEndpoint(ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(requestBody));
            req.setTimeout(60000);
            Http http = new Http();
            HttpResponse res;
            for (Integer attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
                res = http.send(req);
                Integer statusCode = res.getStatusCode();
                if (statusCode == 200) {
                    return parseSuccess(res.getBody());
                }
                if (!(statusCode == 429 || statusCode >= 500) || attempt == MAX_ATTEMPTS) {
                    output.responseText = sanitizeProviderError(statusCode, res.getStatus());
                    output.fullJsonResponse = '{}';
                    return output;
                }
            }
            output.responseText = 'Error: OpenAI did not return a usable response.';
            output.fullJsonResponse = '{}';
        } catch (Exception ex) {
            output.responseText = 'Error: OpenAI callout failed. ' + ex.getMessage();
            output.fullJsonResponse = '{}';
        }
        return output;
    }

    private static OpenAIWebSearchOutput parseSuccess(String body) {
        OpenAIWebSearchOutput output = new OpenAIWebSearchOutput();
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(body);
        output.responseText = extractText(jsonResponse);
        output.fullJsonResponse = JSON.serialize(new Map<String, Object>{
            'responseId' => jsonResponse.get('id'),
            'status' => jsonResponse.get('status')
        });
        return output;
    }

    private static String extractText(Map<String, Object> jsonResponse) {
        List<Object> outputList = (List<Object>) jsonResponse.get('output');
        if (outputList == null) return 'No OpenAI output was returned.';
        List<String> texts = new List<String>();
        for (Object outputItemObj : outputList) {
            Map<String, Object> outputItem = (Map<String, Object>) outputItemObj;
            List<Object> contentArray = (List<Object>) outputItem.get('content');
            if (contentArray == null) continue;
            for (Object contentObj : contentArray) {
                Map<String, Object> content = (Map<String, Object>) contentObj;
                if (content.containsKey('text')) texts.add((String) content.get('text'));
            }
        }
        return texts.isEmpty() ? 'No OpenAI text response was returned.' : String.join(texts, '\n');
    }

    private static String sanitizeProviderError(Integer statusCode, String status) {
        if (statusCode == 401 || statusCode == 403) return 'Error: OpenAI authentication failed. Verify the named credential principal is configured.';
        if (statusCode == 429) return 'Error: OpenAI rate limit exceeded. Please try again later.';
        if (statusCode >= 500) return 'Error: OpenAI is temporarily unavailable. Please try again later.';
        return 'Error: OpenAI request failed with HTTP ' + statusCode + (String.isBlank(status) ? '.' : ' ' + status + '.');
    }
}
