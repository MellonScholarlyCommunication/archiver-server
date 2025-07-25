.PHONY: run demo docker-build docker-run docker-push unlock clean

run:
	./run.sh

server:
	ldn-receiver -port 3007

demo:
	ldn-sender http://localhost:3007/inbox/ data/example.jsonld

docker-build:
	docker build . -t hochstenbach/archiver-server:v0.0.1

docker-run:
	docker run --rm -p 3007:3007 -v `pwd`/tmp:/app/tmp -v `pwd`/inbox:/app/inbox -v `pwd`/error:/app/error hochstenbach/archiver-server:v0.0.1	

docker-interactive:
	docker run --rm -v `pwd`/tmp:/app/tmp -v `pwd`/inbox:/app/inbox -v `pwd`/error:/app/error -it hochstenbach/archiver-server:v0.0.1 sh

docker-push:
	docker push hochstenbach/archiver-server:v0.0.1

unlock:
	rm tmp/lock
	
clean:
	rm -f error/* tmp/* inbox/* public/*