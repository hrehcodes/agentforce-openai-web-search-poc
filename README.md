# Agentforce - OpenAI Web Search POC

A proof of concept Agentforce action that calls OpenAI Responses API web search and formats the output through Flow and Prompt Builder.

This repository contains the Salesforce DX source retrieved from the `Agentforce - OpenAI Web Search POC` unmanaged 1GP package hosted in the `pamigration` org. It is intended to be deployable as source-controlled metadata and to serve as implementation documentation for the solution.

## Solution Highlights
- The Apex action calls https://api.openai.com/v1/responses with web_search enabled.
- The Flow accepts the OpenAI API key and search query as inputs and formats the answer with a prompt template.

## Architecture
Typical execution path:

1. An Agentforce action or topic receives a user request.
2. The action invokes a Flow, Prompt Builder template, or Apex invocable target.
3. Supporting Apex, Prompt Builder templates, and Salesforce metadata perform the callout, extraction, generation, formatting, or record update.
4. The result is returned to Agentforce or stored in Salesforce records for follow-up work.

## Metadata Inventory
- GenAiFunctions: `OpenAI_Web_Research_Agent_Action`
- Prompt templates: `OpenAI_Web_Search_Answer_Formatter`
- Flows: `OpenAI_Web_Research_Flow`
- Apex classes: `OpenAIWebSearchAction`
- Integration metadata: 1 credential/remote-site component(s)

## Agentforce Actions and Topics
- `OpenAI_Web_Research_Agent_Action` -> `OpenAI_Web_Research_Flow` (flow) - This Flow makes an API call to the OpenAI Web Research API call.

## Flows
- `OpenAI_Web_Research_Flow` (OpenAI Web Research Flow) status `Active` type `AutoLaunchedFlow` - This Flow makes an API call to the OpenAI Web Research API call. Key actions: Final Answer Formatter (generatePromptResponse: OpenAI_Web_Search_Answer_Formatter), OpenAI Web Search API Call (apex: OpenAIWebSearchAction).

## Prompt Templates
- `OpenAI_Web_Search_Answer_Formatter` - This prompt template formats the final answer from the OpenAI Web Search Agent Action. (1 version(s); statuses: Published; inputs: `Search_Query`, `OpenAI_Web_Search_Answer`, `OpenAI_Web_Search_Full_JSON`)

## Apex
Apex runtime classes: `OpenAIWebSearchAction`

Apex test classes: None

Invocable methods and key callouts:
- OpenAIWebSearchAction: Call OpenAI Web Search - Calls the OpenAI Web Search endpoint with the provided API key and search query.
- Observed endpoints: `https://api.openai.com/v1/responses`

## Data Model and UI
- None retrieved.

## Integrations and Credentials
- Remote Site Setting `OpenAI` -> `https://api.openai.com`
- Apex endpoints/callouts observed: `https://api.openai.com/v1/responses`

No credential secret values were included in the retrieved metadata. Any API keys or named-principal secrets must be configured in the target org after deployment.

## Prerequisites
- Salesforce org with Metadata API support and Salesforce CLI access.
- Agentforce and Prompt Builder features enabled for metadata that uses GenAiFunction, GenAiPlugin, or GenAiPromptTemplate.
- Permission to deploy Apex, Flow, Prompt Builder, Named Credential, External Credential, and custom object metadata as applicable.
- Access to any external API provider used by this package.

## Deployment
Authenticate to the target org, then validate first:

```bash
sf org login web --alias <target-org>
sf project deploy start --dry-run --manifest manifest/package.xml --target-org <target-org> --wait 30
```

Deploy after the dry run succeeds:

```bash
sf project deploy start --manifest manifest/package.xml --target-org <target-org> --wait 30
```

## Post-Deploy Setup
- Provide an OpenAI API key to the Flow or agent action input.
- Verify the OpenAI remote site setting is active.
- Review whether the API key should be moved to Named Credential / External Credential before production use.

## Testing and Validation
- Run a metadata dry run before deploying to a shared org.
- Run Apex tests listed above when present.
- Open each Flow in Flow Builder and confirm it is active or activate it after reviewing org-specific references.
- Open Prompt Builder templates and confirm the expected published version, model, and inputs.
- Test the Agentforce action with a low-risk sample prompt before giving it to end users.

## Package Provenance
- Source package: `Agentforce - OpenAI Web Search POC`
- MetadataPackageId: `033Hn000000hMY2IAM`
- Retrieved from org alias: `pamigration`
- Package versions observed: `1.0.0 Beta (Beta Release)`
- Repository name: `agentforce-openai-web-search-poc`

## Notes for Maintainers
- Keep generated secrets, local org auth files, `.sf`, `.sfdx`, and deployment output out of source control.
- Treat prompt templates and Agentforce action descriptions as production behavior, not just documentation.
- For production hardening, prefer Named Credential and External Credential patterns over passing API keys directly through Flow variables.
