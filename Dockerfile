FROM nvidia/cuda:10.1-base-ubuntu18.04

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ARG CPU_GPU=gpu

RUN apt-get update --fix-missing && \
    apt-get install --no-install-recommends \
    wget software-properties-common pkg-config build-essential unzip git \
    libglu1-mesa -y && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/local/src/*

# Limited User
RUN groupadd -g 999 appuser && \
    useradd -r -u 1000 -g appuser appuser

RUN mkdir /envs /home/appuser /inference
RUN chown -R appuser /opt /envs /home/appuser /inference

USER appuser

# install miniconda as system python
RUN wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.5.4-Linux-x86_64.sh -O /opt/miniconda.sh && \
    /bin/bash /opt/miniconda.sh -b -p /opt/conda

ENV PATH /opt/conda/bin:$PATH
COPY *.yml /envs/

# create environments
RUN conda env create -f /envs/py-${CPU_GPU}.yml && \
    conda env create -f /envs/r-${CPU_GPU}.yml && \
    conda clean -i -l -t -y

# post-environment installs for R
COPY ./package_installs*.R /envs/
RUN /opt/conda/envs/r-cpu/bin/R -f /envs/package_installs_${CPU_GPU}.R

COPY ./entrypoint.sh /inference/entrypoint.sh
WORKDIR /inference
RUN chmod +x ./entrypoint.sh

# Execute the entrypoint.sh script inside the container when we do docker run
CMD ["/bin/bash", "/inference/entrypoint.sh"]
