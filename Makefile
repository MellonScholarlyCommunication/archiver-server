.PHONY: run demo docker-build docker-run docker-push unlock clean

run:
	./run.sh

demo:
	ldn-sender http://localhost:3333/inbox/ data/example.jsonld

docker-build:
	docker build . -t hochstenbach/archiver-server:v0.0.1

docker-run:
	docker run -p 3006:3006 --rm hochstenbach/archiver-server:v0.0.1	

docker-push:
	docker push hochstenbach/archiver-server:v0.0.1

unlock:
	rm tmp/lock
	
clean:
	rm -rf error/* tmp/*
