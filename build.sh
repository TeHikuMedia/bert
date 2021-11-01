set -ex

export SENTENCEPIECE_DIR=../sentencepiece

mkdir ${SENTENCEPIECE_DIR}/models
cp -r /output/sample_corpus.sentences 
cp -r /output/* ${SENTENCEPIECE_DIR}/models

make pretraining_data

cp tf_examples.tfrecord
