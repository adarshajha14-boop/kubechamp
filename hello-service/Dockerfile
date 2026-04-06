# Build stage
FROM golang:1.21-alpine as builder
WORKDIR /build
RUN apk add --no-cache git

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

# runtime stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /build/app .

EXPOSE 8080
CMD ["./app"]