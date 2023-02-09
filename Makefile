.PHONY: image test citest release

IMAGE_NAME ?= codeclimate/codeclimate-duplication
RELEASE_TAG ?= latest

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

release:
	docker tag $(IMAGE_NAME) $(RELEASE_REGISTRY)/codeclimate-coffeelint:$(RELEASE_TAG)
	docker push $(RELEASE_REGISTRY)/codeclimate-coffeelint:$(RELEASE_TAG)
