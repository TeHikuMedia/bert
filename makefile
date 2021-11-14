REPO_NAME := $(shell basename `git rev-parse --show-toplevel` | tr '[:upper:]' '[:lower:]')
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')
DOCKER_REGISTRY := 473856431958.dkr.ecr.ap-southeast-2.amazonaws.com
IMAGE := $(DOCKER_REGISTRY)/$(REPO_NAME)
HAS_DOCKER ?= $(shell which docker)
RUN ?= $(if $(HAS_DOCKER), docker run $(DOCKER_ARGS) --gpus all --rm -v $$(pwd)/..:/home/kaimahi/language-models/ -w /home/kaimahi/language-models/$(REPO_NAME) -u $(UID):$(GID) $(IMAGE))
UID ?= kaimahi
GID ?= kaimahi
DOCKER_ARGS ?=

BERT_MODEL_NAME ?= base_bert
BERT_MODEL_DIR ?= models/$(BERT_MODEL_NAME)

SENTENCEPIECE_DIR ?= ../sentencepiece
SENTENCEPIECE_MODEL_NAME ?= sample
SENTENCEPIECE_MODEL_DIR ?= $(SENTENCEPIECE_DIR)/models/$(SENTENCEPIECE_MODEL_NAME)

NUM_TRAIN_STEPS ?= 10

.PHONY: docker docker-push docker-pull enter enter-root

pretraining: $(BERT_MODEL_DIR)/$(BERT_MODEL_NAME).ckpt

$(BERT_MODEL_DIR)/$(BERT_MODEL_NAME).ckpt: $(SENTENCEPIECE_MODEL_NAME).tfrecord
	$(RUN) python3 run_pretraining.py \
  --input_file=$< \
  --output_dir=$(BERT_MODEL_DIR) \
  --do_train=True \
  --do_eval=True \
  --bert_config_file=$(BERT_MODEL_DIR)/bert_config.json \
  --train_batch_size=32 \
  --max_seq_length=128 \
  --max_predictions_per_seq=20 \
  --num_train_steps=$(NUM_TRAIN_STEPS) \
  --num_warmup_steps=10 \
  --learning_rate=2e-5 \
  --use_tpu=False

$(SENTENCEPIECE_MODEL_DIR)/$(SENTENCEPIECE_MODEL_NAME)_vocab.txt: \
	$(SENTENCEPIECE_MODEL_DIR)/$(SENTENCEPIECE_MODEL_NAME).vocab
	cat $< | awk -F ' ' '{print $$1}' > $@

$(SENTENCEPIECE_MODEL_NAME).tfrecord: \
	create_pretraining_data.py \
	$(SENTENCEPIECE_MODEL_DIR)/$(SENTENCEPIECE_MODEL_NAME).sentences \
	$(SENTENCEPIECE_MODEL_DIR)/$(SENTENCEPIECE_MODEL_NAME)_vocab.txt
	$(RUN) python3 create_pretraining_data.py \
  --input_file=$(SENTENCEPIECE_MODEL_DIR)/$(SENTENCEPIECE_MODEL_NAME).sentences \
  --output_file=$@ \
  --vocab_file=$(SENTENCEPIECE_MODEL_DIR)/$(SENTENCEPIECE_MODEL_NAME)_vocab.txt \
  --do_lower_case=True \
  --max_seq_length=128 \
  --max_predictions_per_seq=20 \
  --masked_lm_prob=0.15 \
  --random_seed=12345 \
  --dupe_factor=5

clean:
	rm -rf models
	git checkout models

JUPYTER_PASSWORD ?= jupyter
JUPYTER_PORT ?= 8888
.PHONY: jupyter
jupyter: UID=root
jupyter: GID=root
jupyter: DOCKER_ARGS=-u $(UID):$(GID) --rm -it -p $(JUPYTER_PORT):$(JUPYTER_PORT) -e NB_USER=$$USER -e NB_UID=$(UID) -e NB_GID=$(GID)
jupyter:
	$(RUN) jupyter lab \
		--allow-root \
		--port $(JUPYTER_PORT) \
		--ip 0.0.0.0 \
		--NotebookApp.password=$(shell $(RUN) \
			python3 -c \
			"from IPython.lib import passwd; print(passwd('$(JUPYTER_PASSWORD)'))")

.PHONY: docker-login
docker-login: PROFILE=default
docker-login:
	# First run `$$aws configure` to get your AWS credentials in the right place
	docker login -u AWS --password \
	$$(aws ecr get-login-password --profile $(PROFILE) --region ap-southeast-2) \
	"$(DOCKER_REGISTRY)"

docker: docker-login
	docker build $(DOCKER_ARGS) -t $(IMAGE) .
	docker tag $(IMAGE) $(IMAGE):$(GIT_TAG) && docker push $(IMAGE):$(GIT_TAG)
	docker tag $(IMAGE) $(IMAGE):latest && docker push $(IMAGE):latest
	docker push $(IMAGE)

docker-push:
	docker push $(IMAGE):$(GIT_TAG)
	docker push $(IMAGE):latest

docker-pull:
	docker pull $(IMAGE):$(GIT_TAG)
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

enter: DOCKER_ARGS=-it
enter:
	$(RUN) bash

enter-root: DOCKER_ARGS=-it
enter-root: UID=root
enter-root: GID=root
enter-root:
	$(RUN) bash
