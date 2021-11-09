set -ex

export SENTENCEPIECE_DIR=../sentencepiece

# Copy text corpus from sentencepiece job
cp -r /input/sentencepiece/corpus ../

# Put sentencepiece model in the right place
mkdir ${SENTENCEPIECE_DIR}/models
cp -r /input/sentencepiece/models ${SENTENCEPIECE_DIR}

# Show the cuda version
nvcc --version

# Do the work
make pretraining

# Save the results
cp *.tfrecord /output
cp models/ /output
cp pretraining_output/ /output
