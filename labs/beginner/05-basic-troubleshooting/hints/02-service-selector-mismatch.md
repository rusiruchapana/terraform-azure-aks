# Hint - Service Selector Mismatch

The pod may be Running, but the Service may not have endpoints.

Use:

    kubectl get endpoints -n beginner-troubleshooting
    kubectl get pods -n beginner-troubleshooting --show-labels
    kubectl describe svc selector-demo -n beginner-troubleshooting

Questions:

- What labels does the pod have?
- What selector does the Service use?
- Do they match?

You probably need to make the Service selector match the pod labels.
