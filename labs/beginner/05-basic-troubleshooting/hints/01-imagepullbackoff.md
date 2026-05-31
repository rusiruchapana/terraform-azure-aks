# Hint - ImagePullBackOff

Look at the image field in the Deployment.

Use:

    kubectl describe pod -n beginner-troubleshooting <pod-name>

Check the Events section.

Questions:

- What image is Kubernetes trying to pull?
- Does the image tag exist?
- Is the problem the registry, image name, or image tag?

You probably need to use a valid image tag.
