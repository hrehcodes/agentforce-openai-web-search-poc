@IsTest
private class OpenAIWebSearchAction_Test {
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assert(req.getEndpoint().contains('callout:OpenAI_API'));
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"id":"resp_123","status":"completed","output":[{"type":"web_search_call"},{"type":"message","content":[{"type":"output_text","text":"OpenAI answer"}]}]}');
            return res;
        }
    }
    private class RateLimitMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(429);
            res.setStatus('Too Many Requests');
            res.setBody('{"error":"provider body"}');
            return res;
        }
    }
    @IsTest static void returnsOpenAIText() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        OpenAIWebSearchAction.OpenAIWebSearchInput input = new OpenAIWebSearchAction.OpenAIWebSearchInput();
        input.searchQuery = 'Salesforce Agentforce';
        List<OpenAIWebSearchAction.OpenAIWebSearchOutput> outputs = OpenAIWebSearchAction.callOpenAIWebSearch(new List<OpenAIWebSearchAction.OpenAIWebSearchInput>{ input });
        System.assertEquals('OpenAI answer', outputs[0].responseText);
        System.assert(outputs[0].fullJsonResponse.contains('resp_123'));
    }
    @IsTest static void sanitizesRateLimit() {
        Test.setMock(HttpCalloutMock.class, new RateLimitMock());
        OpenAIWebSearchAction.OpenAIWebSearchInput input = new OpenAIWebSearchAction.OpenAIWebSearchInput();
        input.searchQuery = 'Salesforce';
        List<OpenAIWebSearchAction.OpenAIWebSearchOutput> outputs = OpenAIWebSearchAction.callOpenAIWebSearch(new List<OpenAIWebSearchAction.OpenAIWebSearchInput>{ input });
        System.assert(outputs[0].responseText.contains('rate limit'));
        System.assert(!outputs[0].responseText.contains('provider body'));
    }
}
