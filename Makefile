.PHONY: image test citest qa

IMAGE_NAME ?= codeclimate/codeclimate-duplication

image:
	docker build --rm -t $(IMAGE_NAME) .

test: image
	docker run --tty --interactive --rm $(IMAGE_NAME) bundle exec rspec $(RSPEC_ARGS)

citest:
	docker run --rm $(IMAGE_NAME) bundle exec rake

qa: image
	# requires QA=true to run locally
	# optionally pass LANGUAGE=x
	qa/bin/clone_and_test_examples qa/examples $(IMAGE_NAME)
