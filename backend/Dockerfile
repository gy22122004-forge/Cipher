FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o cipher_server ./cmd/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates gcc musl-dev sqlite
WORKDIR /root/
COPY --from=builder /app/cipher_server .
EXPOSE 8080
ENV GIN_MODE=release
CMD ["./cipher_server"]
