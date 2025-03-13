.PHONY: all demo unlock clean

all:
	./run.sh

demo:
	ldn-sender http://localhost:3333/inbox/ data/example.jsonld

unlock:
	rm tmp/lock
	
clean:
	rm -rf error/* tmp/*
