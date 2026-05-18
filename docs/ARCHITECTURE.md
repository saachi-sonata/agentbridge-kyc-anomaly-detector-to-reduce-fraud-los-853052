# Architecture Documentation

## Overview
This CodeAct implements KYC Anomaly Detector to reduce fraud loss for Banking & Finance use cases.

## Components
1. **Transaction Intake**: Collect, validate and normalize alerts from Fraud Platform; attach a runId and timestamp for traceability.
2. **Program Synthesis**: Execute program synthesis phase for the CodeAct pattern: persist interim state, enforce guardrails, and emit structured JSON results.
3. **Execution**: Execute execution phase for the CodeAct pattern: persist interim state, enforce guardrails, and emit structured JSON results.
4. **Case Management**: Case Management across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
5. **Break Resolution**: Break Resolution across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
6. **Settlement**: Settlement across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
7. **Sanctions Screening**: Sanctions Screening across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
8. **Regulatory Report**: Assemble final payload with status, artifacts, KPIs and audit trail; store to Core Banking; return response JSON for the client.

## Data Flow
- Input: Transaction Intake
- Processing: 8 sequential steps
- Output: Regulatory Report
