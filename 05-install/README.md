# Containerlab Installation

Use the quick-install bash script, which supports multiple Linux distributions. The following will be installed:

* docker
* latest containerlab release,
* `gh` cli

Try it out with the simple one-liner:

```bash
curl -L http://containerlab.dev/setup | \
sudo bash -s "all"
```

The automation script adds your user to the `docker` linux group, in order for these changes to take effect, log out from the current session and log back in.

Check that docker is installed and running:

```bash
docker run --rm hello-world
# Expected output: Hello from Docker!
```

Check that containerlab is installed successfully:

```bash
containerlab version
```

* Alternative Containerlab installation options are available [here](https://containerlab.dev/install/).
* Alternative Docker installation options can be found [here](https://docs.docker.com/engine/install/).