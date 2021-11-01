set -ex

export SENTENCEPIECE_DIR=../sentencepiece

# Copy text corpus from sentencepiece job
cp -r /sentencepiece-input/corpus ../

# Put sentencepiece model in the right place
mkdir ${SENTENCEPIECE_DIR}/models
cp -r /sentencepiece-input/sample_corpus.sentences
cp -r /sentencepiece-input/models ${SENTENCEPIECE_DIR}

# Do the work
make pretraining_data

# Save the results
cp tf_examples.tfrecord
