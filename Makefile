.PHONY: image test citest release

IMAGE_NAME ?= codeclimate/codeclimate-duplication

image:
	docker build --rm -t $(IMAGE_NAME) .

test: image
	docker run --tty --interactive --rm $(IMAGE_NAME) bundle exec rspec $(RSPEC_ARGS)

citest:
	docker run --rm $(IMAGE_NAME) bundle exec rake

bundle:
	docker run --rm \
	  --entrypoint /bin/sh \
	  --volume $(PWD):/usr/src/app \
	  $(IMAGE_NAME) -c "bundle $(BUNDLE_ARGS)"

release: image
	docker tag $(IMAGE_NAME) \
		us.gcr.io/code_climate/codeclimate-duplication:$(RELEASE_TAG)
	docker push us.gcr.io/code_climate/codeclimate-duplication:$(RELEASE_TAG)
