# GitOps drift from an imperative production change
Primary signal: Live replica count differs from Git and Argo CD reports OutOfSync

## Mission

An operator scales the application manually. Determine the declared state, observe Argo CD's reconciliation, and explain when self-heal is helpful versus dangerous.

## Requirement

Install Argo CD and register this repository before starting the scenario.
