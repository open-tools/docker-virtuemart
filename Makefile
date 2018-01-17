all: j3vm3 
j3vm3: FORCE
	cd j3vm3_full && docker build -t registry.open-tools.net/opentools/docker-virtuemart/j3vm3:latest . 

push:
	cd j3vm3_full && docker push 
FORCE:
