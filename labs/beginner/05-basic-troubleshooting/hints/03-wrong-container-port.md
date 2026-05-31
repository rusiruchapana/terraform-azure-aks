# Hint - Wrong Container Port

The pod may be Running and the Service may have endpoints, but traffic can still fail.

Use:

    kubectl describe svc wrong-port-demo -n beginner-troubleshooting
    kubectl get pods -n beginner-troubleshooting

Questions:

- What port does NGINX listen on?
- What targetPort does the Service use?
- Do they match?

You probably need to update the Service targetPort.
