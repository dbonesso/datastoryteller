ARG IMAGE_TAG

FROM datastoryteller/spark-py:${IMAGE_TAG}

USER root

RUN apt-get update && apt install -y \
    wget sudo \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /var/cache/apt/*

# Install pip
RUN apt-get update && apt-get install -y python3-pip 

# Add all python packages  needed
RUN pip install \
    notebook==6.4.2 \
    ipynb==0.5.1 \
    sparkmonitor==2.1.1 \
    pyspark==3.3.0 \
    jupyter_contrib_nbextensions \
    jupyter_nbextensions_configurator

# install extension to monitor spark as root
RUN \
jupyter nbextension install sparkmonitor --py --system --symlink && \
jupyter nbextension enable  sparkmonitor --py --system && \
ln -s /usr/local/lib/python3.9/dist-packages/sparkmonitor/listener_2.12.jar /opt/spark/jars/listener_2.12.jar

# Start Jupyter Lab Service as root
RUN mkdir -p /home/joyvan/
CMD jupyter lab --port=8888 --ip=0.0.0.0 --no-browser --allow-root \
    --NotebookApp.token='' --notebook-dir=/home/joyvan/  \
    --LabApp.token='' --LabApp.disable_check_xsrf=True 

# Add regular user with sudo privilliges
RUN useradd -ms /bin/bash joyvan && usermod -aG sudo joyvan
RUN echo "joyvan     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN chown -R joyvan:users /home/joyvan
EXPOSE 8888 4040 7777 2222

# Switch to regular user
USER joyvan
WORKDIR /home/joyvan

# Create profile for regular user and enable sparkmonitor extension
# https://pypi.org/project/jupyterlab-sparkmonitor/
RUN ipython profile create  && \
echo "c.InteractiveShellApp.extensions.append('sparkmonitor.kernelextension')" >> $(ipython profile locate default)/ipython_config.py && \
echo "c.InteractiveShellApp.extensions.append('sparkmonitor.kernelextension')" >>  $(ipython profile locate default)/ipython_kernel_config.py
