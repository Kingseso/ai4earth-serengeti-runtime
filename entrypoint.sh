#!/bin/bash
set -ex

processor="gpu"

{
    cd /inference

    # check for gpu with nvidia-smi
    if [ $(which nvidia-smi) ]
    then
        :
    else
        echo "GPU unavailable; falling back to CPU."
        processor="cpu"
    fi

    echo "Unpacking submission..."
    unzip ./submission/submission.zip -d .

    if [ -f "main.py" ]
    then
        source activate py-$processor
        echo "Running submission with Python "
        python main.py
    elif [ -f "main.R" ]
    then
        source activate r-$processor
        echo "Running submission with R"
        R -f main.R
    else
        echo "ERROR: Could not find main.py or main.R in submission.zip"
        exit 1
    fi

    echo "Exporting submission.csv result..."

    # Valid scripts must create a "submission.csv" file within the same directory as main
    if [ -f "submission.csv" ]
    then
        echo "Script completed its run."
        cp submission.csv ./submission/submission.csv
    else
        echo "ERROR: Script did not produce a submission.csv file in the main directory."
        exit 1
    fi

    echo "Completed execution."
    exit 0
} |& tee "/inference/submission/log.txt"

# copy for additional log uses
cp /inference/submission/log.txt /tmp/log
