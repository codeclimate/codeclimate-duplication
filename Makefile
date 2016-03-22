.PHONY: image test citest

IMAGE_NAME ?= codeclimate/codeclimate-duplication

image:
	docker build --rm -t $(IMAGE_NAME) .

test: image
	docker run --tty --interactive --rm $(IMAGE_NAME) bundle exec rake

citest:
	docker run --rm $(IMAGE_NAME) bundle exec rake
