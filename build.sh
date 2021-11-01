set -ex

export SENTENCEPIECE_DIR=../sentencepiece

# Copy text corpus from sentencepiece job
cp -r /input/sentencepiece/corpus ../

# Put sentencepiece model in the right place
mkdir ${SENTENCEPIECE_DIR}/models
cp -r /input/sentencepiece/sample_corpus.sentences ${SENTENCEPIECE_DIR}
cp -r /input/sentencepiece/models ${SENTENCEPIECE_DIR}

# Do the work
make sample_data

# Save the results
cp tf_examples.tfrecord /output
