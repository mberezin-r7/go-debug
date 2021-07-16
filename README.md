# Delve Debugger for Golang

This script runs a Delve Go debugging server in a container. It creates a `docker/debug/` directory in your project, generates a Dockerfile there with your runtime arguments, builds your project binary, and starts the Delve server.

This script also bridges your project directory `docker/debug/mount/` to a Docker bind mount in the container at `/mount/` which allows you to pass through test files between your host machine and the container.

The Delve debug server may take a long time to start because the script rebuilds your project with a new container on every run.

## Usage

```text
delve.sh <Go project path relative to GOPATH> <path to built binary relative to Go project path> <built binary arguments ...

Example: delve.sh src/github.com/rapid7/icon-plugin build/bin/icon-plugin generate --regenerate python /mount/plugin.spec.yaml"
```

Resolved under `GOPATH`, the first argument `src/github.com/rapid7/icon-plugin` is the path to the Go project that we want to debug.
Resolved under the Go project path, the second argument `build/bin/icon-plugin` is the path to the executable binary that is generated by the Go project `make all` command. Note this path includes the file, and is not just its residing directory.
The remaining arguments `generate --regenerate python /mount/plugin.spec.yaml` are passed to the `icon-plugin` binary as its own runtime arguments.

## Integration with JetBrains IDEs

To integrate this script with the IntelliJ or Goland debug tool, you must create a new run/debug configuration for a particular execution (meaning running a fixed program with a fixed set of arguments in a fixed working directory). Each individual execution should have its own run/debug configuration.

In the top right of your IDE, click on your run configurations dropdown menu and click **Edit Configurations...**. You should now see the the **Run/Debug Configurations** menu. Click the **+** in the top left, and select the **Go Remote** template. Leave host as localhost and port as 2345. Click the **+** under the **Before launch** section and click **Run External tool**. The **Create Tool** window should now appear. Click the **+** in the top left. You should now see the **Create Tool** window.

Set **Program** to the path to the **delve.sh** script on your host machine. If you cloned this repository under `~/dev` then your program path would be `/Users/Username/dev/go-debug/delve.sh`.
As listed under Usage, there are two arguments required, and optional additional parameters that get passed to your project's built binary.
Working directory must be a path parent to the program path.
Keep in mind that this external tool instance is one execution configuration. You may have several "external tools" that use the same program but have different arguments.
Click **OK** on all windows and return to your main IDE window. Select the new configuration from the dropdown and run.

If the IDE cannot pass the pre-launch step, try removing the **Before launch** step and run the script with the same parameters from an external terminal.

## Requirements

* Git
* Golang
* Docker
* grep
* sed

## References

* [Delve](https://github.com/go-delve/delve) is the preferred debugger tool for Golang.
* [golangforall.com: Remote debugging with Delve](https://golangforall.com/en/post/go-docker-delve-remote-debug.html)
  * [Go remote debugging example project](https://github.com/antelman107/go-remote-debug-delve)