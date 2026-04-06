.PHONY: build docker-build clean

build:
	go build -o hello-service main.go

docker-build:
	docker build -t hello-service:latest .

clean:
	rm -f hello-service