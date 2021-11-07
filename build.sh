set -ex

export SENTENCEPIECE_DIR=../sentencepiece

# Copy text corpus from sentencepiece job
cp -r /input/sentencepiece/corpus ../

# Put sentencepiece model in the right place
mkdir ${SENTENCEPIECE_DIR}/models
cp -r /input/sentencepiece/full_corpus.sentences ${SENTENCEPIECE_DIR}
cp -r /input/sentencepiece/models ${SENTENCEPIECE_DIR}

# Do the work
make full_pretraining_data.tfrecord

# Save the results
cp full_pretraining_data.tfrecord /output
