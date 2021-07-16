#!/usr/bin/env bash
# delve.sh should be run from its own file path.

# Recommend to alias delve=source $HOME/dev/go-debug/delve.sh

# Print help section
if [[ -z "$1" ]]; then
    echo "Usage: delve.sh <Go project path relative to GOPATH> <path to built binary relative to Go project path> <built binary arguments ...>"
    echo
    echo "Example usage: delve.sh src/github.com/rapid7/icon-plugin build/bin/icon-plugin generate --regenerate python /mount/plugin.spec.yaml"
    echo
    echo "This script runs a Delve Go debugging server in a container. It creates a docker/debug/ directory in your project, generates a Dockerfile there with your runtime arguments, builds your project binary, and starts the Delve server."
    echo "This script also bridges your project directory docker/debug/mount/ to a Docker bind mount in the container at /mount/ which allows you to pass through test files between your host machine and the container."
    exit
fi

# Extract runtime arguments                                        Examples
PROJECT_PATH="$GOPATH/$1"                                          # ~/go/src/github.com/rapid7/icon-plugin
PROJECT_COPY="/go/$(realpath $PROJECT_PATH --relative-to $GOPATH)" # /go/src/github.com/rapid7/icon-plugin
PROJECT_NAME="$(basename $PROJECT_PATH)"                           # icon-plugin
EXECUTE_PATH="$2"                                                  # build/bin/icon-plugin
EXECUTE_FLAG="${@:3}"                                              # generate --regenerate python 

# Make project/docker/debug/mount directory if it doesn't exist
if [[ ! -d "$PROJECT_PATH/docker/debug/mount" ]]; then
    echo -n "Making path $PROJECT_PATH/docker/debug/mount... "
    mkdir -p "$PROJECT_PATH/docker/debug/mount"
    echo "done."
fi

# Copy Dockerfile to project/docker/debug if not present
if [[ ! -f "$PROJECT_PATH/docker/debug/Dockerfile" ]]; then
    echo -n "Copying Dockerfile... "
    cp -i "./Dockerfile" "$PROJECT_PATH/docker/debug/"
    echo "done."
fi

# Fill in project path and executable path to the Dockerfile variables if the template text is present
if [[ ! -z $(grep "MY_PROJECT_PATH" "$PROJECT_PATH/docker/debug/Dockerfile") || ! -z $(grep "MY_EXECUTE_PATH" "$PROJECT_PATH/docker/debug/Dockerfile") ]]; then
    echo -n "Filling in Dockerfile template... "
    sed -i '' "s|MY_PROJECT_PATH|$PROJECT_COPY|" "$PROJECT_PATH/docker/debug/Dockerfile"
    sed -i '' "s|MY_EXECUTE_PATH|$EXECUTE_PATH|" "$PROJECT_PATH/docker/debug/Dockerfile"
    echo "done."
fi

# Go to the project directory inside this script's process
cd "$PROJECT_PATH"

# Remove old container if present
if [[ ! -z "$(docker container ls --all | grep $PROJECT_NAME-debug)" ]]; then
    echo "Removing old $PROJECT_NAME-debug container..."
    docker container rm -f "$PROJECT_NAME-debug"
    echo "Done."
fi

# Build Delve container for this project
echo "Building $PROJECT_NAME-debug container..."
docker build -f ./docker/debug/Dockerfile -t "$PROJECT_NAME-debug" .
echo "Done."

# Start Delve container
echo "Starting $PROJECT_NAME-debug..."
docker run --detach --interactive --tty --name "$PROJECT_NAME-debug" --volume "$PROJECT_PATH/docker/debug/mount:/mount/" --publish 2345:2345 "$PROJECT_NAME-debug" --listen=:2345 --headless=true --log=true --log-output=debugger,debuglineerr,gdbwire,lldbout,rpc --accept-multiclient --api-version=2 exec /app "$EXECUTE_FLAG"
echo "Done."

# Offer to show container logs
read -p "Tail container logs? " YN
if [[ "$YN" == [Yy]* ]]; then
    echo
    docker logs -f "$PROJECT_NAME-debug"
fi
