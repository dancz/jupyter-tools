#!/bin/bash
nvidia-smi
sleep 2
echo "Enter path to jupyter notebooks:"
read path
echo 'Download and install Miniconda'
curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o Miniconda3-latest-Linux-x86_64.sh
wait
bash ./Miniconda3-latest-Linux-x86_64.sh -b
wait

echo 'Initialize Conda and create virtual environment'
sleep 2
./miniconda3/bin/conda init
source ~/.bashrc
conda update -y -n base -c defaults conda
conda create -y --name tf python=3.9
wait

echo 'Activate virtual environment and install required packages'
sleep 2
conda deactivate
conda activate tf
conda install -y -c conda-forge cudatoolkit=11.8.0
#conda install -y -c nvidia cuda-toolkit
pip3 install --upgrade pip
pip3 install nvidia-cudnn-cu11==8.6.0.163
#pip3 install nvidia-cudnn-cu11
sleep 2
CUDNN_PATH=$(dirname $(python -c "import nvidia.cudnn;print(nvidia.cudnn.__file__)"))
echo 'CUDNN_PATH:'
echo $CUDNN_PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib/:$CUDNN_PATH/lib
echo 'LD_LIBRARY_PATH:'
echo $LD_LIBRARY_PATH
sleep 2
mkdir -p $CONDA_PREFIX/etc/conda/activate.d
echo 'CUDNN_PATH=$(dirname $(python -c "import nvidia.cudnn;print(nvidia.cudnn.__file__)"))' >> $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib/:$CUDNN_PATH/lib' >> $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh
pip3 install tensorflow==2.12.* jupyterlab matplotlib ipykernel tensorflow_hub pandas nvidia-pyindex yfinance
pip install -U scikit-learn nvidia-tensorrt

echo 'Enable jupyter http (connection from colab)'
pip install -U "jupyter-server<2.0.0"
pip install jupyter_http_over_ws
pip install -U "jupyter-client==7.4.9"

wait
python3 -c "import tensorflow as tf; print(tf.reduce_sum(tf.random.normal([1000, 1000])))"
sleep 2
python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
sleep 3
cd $path
#jupyter lab
jupyter notebook --NotebookApp.allow_origin='https://colab.research.google.com' --port=8888 --NotebookApp.port_retries=0