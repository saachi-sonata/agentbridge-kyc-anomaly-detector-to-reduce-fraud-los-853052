# API Documentation

## Endpoints
### Transaction Intake
- **Description**: Collect, validate and normalize alerts from Fraud Platform; attach a runId and timestamp for traceability.
- **Type**: Processing

### Program Synthesis
- **Description**: Execute program synthesis phase for the CodeAct pattern: persist interim state, enforce guardrails, and emit structured JSON results.
- **Type**: Processing

### Execution
- **Description**: Execute execution phase for the CodeAct pattern: persist interim state, enforce guardrails, and emit structured JSON results.
- **Type**: Processing

### Case Management
- **Description**: Case Management across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
- **Type**: Processing

### Break Resolution
- **Description**: Break Resolution across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
- **Type**: Processing

### Settlement
- **Description**: Settlement across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
- **Type**: Processing

### Sanctions Screening
- **Description**: Sanctions Screening across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
- **Type**: Processing

### Regulatory Report
- **Description**: Assemble final payload with status, artifacts, KPIs and audit trail; store to Core Banking; return response JSON for the client.
- **Type**: Processing
