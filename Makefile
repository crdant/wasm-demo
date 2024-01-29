PROJECT_DIR := $(shell pwd)
APPLICATION := "Hello, Replicated"
VERSION     := $(shell yq .version $(PROJECT_DIR)/charts/hello-replicated/Chart.yaml)
CHANNEL     := $(shell git branch --show-current)

MANIFEST_DIR := $(PROJECT_DIR)/kots
MANIFESTS    := $(shell find $(MANIFEST_DIR) -name '*.yaml' -o -name '*.tgz')

SRC_DIR := $(PROJECT_DIR)/hello-replicated
SRC     := $(shell find $(MANIFEST_DIR) -name '*.go' -o -name '*.toml')
OBJ     := $(shell find $(MANIFEST_DIR) -name '*.go' -o -name '*.toml')

APP_VERSION := $(shell grep '^version = ".*"' $(SRC_DIR)/spin.toml | awk '{ print $3 ; }' | tr -d \")

app:
	@replicated app create $(APPLICATION)

lint: $(MANIFESTS)
	@replicated release lint --yaml-dir $(MANIFEST_DIR)

build: $(SRC)
  @spin build --from $(SRC_DIR)/spin.toml

image: $(OBJ)
  @spin registry push --from $(SRC_DIR)/spin.toml $(REGISTRY):v$(APP_VERSION)

chart:
	@helm package -u charts/hello-replicated -d kots

release: $(MANIFESTS) chart lint
	@replicated release create \
	 	--app ${REPLICATED_APP} \
		--version $(VERSION) \
		--yaml-dir $(MANIFEST_DIR) \
		--ensure-channel \
		--promote $(CHANNEL)
