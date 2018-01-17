IMAGE=registry.open-tools.net/opentools/docker-virtuemart/j3vm3:latest

all: j3vm3 
j3vm3: FORCE
	docker build -t $(IMAGE) . 

push:
	docker push $(IMAGE)
FORCE:
