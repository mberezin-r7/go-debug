FROM golang:1.15-alpine as build

# Configure project pre-build
RUN apk add --update --no-cache git make && rm -rf /var/cache/apk/*
ENV GO111MODULE "auto"
ENV GOPRIVATE "github.com/rapid7"
RUN git config --global url."git@github.com:rapid7/".insteadOf "https://github.com/rapid7/"

# Get build and debug dependencies
RUN go get -u github.com/go-delve/delve/cmd/dlv
RUN go get -u github.com/gobuffalo/packr/packr && go get -u github.com/gobuffalo/packr
RUN go get -u github.com/go-bindata/go-bindata/... && go install github.com/go-bindata/go-bindata

# The following two variables are replaced with runtime arguments to delve.sh script. Examples:
# ENV PROJECT_PATH /go/src/github.com/rapid7/icon-plugin
# ENV EXECUTE_PATH build/bin/icon-plugin
ENV PROJECT_PATH MY_PROJECT_PATH
ENV EXECUTE_PATH MY_EXECUTE_PATH

# current directory context of the process building this Dockerfile should be project root
COPY . $PROJECT_PATH
WORKDIR $PROJECT_PATH

# Build the project
RUN make all

# Project post-build
FROM alpine
# Like in the build stage, the following two variables are replaced with runtime arguments to delve.sh script.
ENV PROJECT_PATH MY_PROJECT_PATH
ENV EXECUTE_PATH MY_EXECUTE_PATH

WORKDIR /
COPY --from=build /go/bin/dlv /dlv
COPY --from=build "$PROJECT_PATH/$EXECUTE_PATH" /app

ENTRYPOINT [ "/dlv" ]
