IMAGE_NAME := waja/php83-fpm

build:
	docker build --rm -t $(IMAGE_NAME) .
	
run:
	@echo docker run --rm -it $(IMAGE_NAME) 
	
shell:
	docker run --rm -it --entrypoint sh $(IMAGE_NAME) -l

test: build
	@if ! [ "$$(docker run --rm -it $(IMAGE_NAME) -v | grep -E '^PHP\s8\.4' | cut -d'.' -f3 --complement)" = "PHP 8.4" ]; then exit 1; fi
