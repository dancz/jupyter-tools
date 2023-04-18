#!/bin/bash

# Author: Dan Samek (dancz)
# Project: https://github.com/dancz/jupyter-tools/

nvidia-smi
echo -n "Enter path to Jupyter notebooks (/mnt/c/notebooks): "
read pathInput
if [ -z "$pathInput" ]
then
  notebookPath="/mnt/c/notebooks"
else
  notebookPath="$pathInput"
fi

tokenHash=""
appToken=""
echo -n "Use fixed token?: [y/N]: "
read choice
if [ "$choice"==[Yy]* ]
then
  tokenHash=$(openssl rand -base64 48 | sha384sum | head -c 48)
  appToken=" --NotebookApp.token=$tokenHash" 
fi

# Download and install Miniconda
curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o Miniconda3-latest-Linux-x86_64.sh
bash ./Miniconda3-latest-Linux-x86_64.sh -b

#Initialize Conda and create virtual environment
./miniconda3/bin/conda init
source ~/.bashrc
conda update -y -n base -c defaults conda
conda create -y --name tf python=3.10

# Activate virtual environment and install required packages
conda deactivate
conda activate tf
conda install -y -c conda-forge cudatoolkit=11.8.0
pip3 install --upgrade pip
pip3 install nvidia-cudnn-cu11==8.6.0.163
CUDNN_PATH=$(dirname $(python -c "import nvidia.cudnn;print(nvidia.cudnn.__file__)"))
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib/:$CUDNN_PATH/lib
mkdir -p $CONDA_PREFIX/etc/conda/activate.d
echo 'CUDNN_PATH=$(dirname $(python -c "import nvidia.cudnn;print(nvidia.cudnn.__file__)"))' >> $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib/:$CUDNN_PATH/lib' >> $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh
pip3 install tensorflow==2.12.* jupyterlab matplotlib ipykernel tensorflow_hub pandas nvidia-pyindex yfinance
pip install -U scikit-learn nvidia-tensorrt

# Enable jupyter http (connection from colab)
pip install -U "jupyter-server<2.0.0"
pip install -U "jupyter-client==7.4.9"
pip install --upgrade "jupyter_http_over_ws>=0.0.7"
jupyter serverextension enable --py jupyter_http_over_ws
python3 -c "import tensorflow as tf; print(tf.reduce_sum(tf.random.normal([1000, 1000])))"
sleep 2
python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"

# Create start file
echo "#!/bin/bash" > ~/bin/jupyterlab
echo "source ~/.bashrc" >> ~/bin/jupyterlab
echo "conda activate tf" >> ~/bin/jupyterlab
echo "cd $notebookPath" >> ~/bin/jupyterlab
echo "jupyter notebook --NotebookApp.allow_origin='https://colab.research.google.com' --port=8888 --NotebookApp.port_retries=0$appToken" >> ~/bin/jupyterlab
chmod +x ~/bin/jupyterlab

bold=$(tput bold)
normal=$(tput sgr0)
echo
echo "*************************************************************************"
if [ -n "$tokenHash" ]
then
echo "App token: $tokenHash"
fi
echo " Type ${bold}jupyterlab${normal} to start jupyter"
echo "*************************************************************************"
