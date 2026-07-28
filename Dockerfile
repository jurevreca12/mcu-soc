FROM hpretl/iic-osic-tools:2026.06
USER root
RUN apt update && \
    apt install -y --only-upgrade python3-pip && \
    apt install -y python3-dev \
                   boolector \
                   netcat-openbsd

RUN useradd -m -u 1000 developer
USER developer

RUN pip install --upgrade pip && \
    pip install  "cython<3.0.0" wheel && \
    pip install  "PyYAML==5.2" --no-build-isolation && \ 
    pip install vcs_versioning pyelftools pexpect && \
    pip install git+https://github.com/jurevreca12/forastero.git@f546470 \
                git+https://github.com/riscv-software-src/riscv-config@54171f2 \
                git+https://github.com/riscv-software-src/riscv-isac@777d2b4 \
                git+https://github.com/riscv-software-src/riscof@aa146d4 \
                git+https://github.com/jurevreca12/pyspike.git@7c92846 \
                git+https://github.com/jurevreca12/riscv-python-model@24daba0 && \
    pip install git+https://github.com/cocotb/cocotb.git@c463647 # installed separetly - version conflict
RUN pip install --force-reinstall pytest && \
    pip install pytest-xdist

USER root
RUN curl -L https://github.com/sifive/elf2hex/archive/refs/tags/v20.08.00.00.tar.gz -o elf2hex.tar.gz && \
    tar -xvzpf elf2hex.tar.gz && \
    rm elf2hex.tar.gz && \
    cd elf2hex-* && \
    ./configure --target=riscv32-unknown-elf && \
    make && \
    make install && \
    cd .. && \
    rm -rf elf2hex-*

RUN git clone https://github.com/YosysHQ/riscv-formal && \
    cd riscv-formal && \
    git checkout 3a2512a22e79d5289f90a5ea2d208b21bba7b352 && \
    mkdir /foss/tools/riscv-formal && \
    cp -r ./checks /foss/tools/riscv-formal/ && \
    cp -r ./bus /foss/tools/riscv-formal/ && \
    cp -r ./insns /foss/tools/riscv-formal/ && \
    cp -r ./monitor /foss/tools/riscv-formal/ && \
    cd .. && \
    rm -rf riscv-formal && \
    sed -i "s/basedir\s=\sf\"{os\.getcwd()}\/\.\.\/\.\.\"/basedir = \"\/foss\/tools\/riscv-formal\"/" \
        /foss/tools/riscv-formal/checks/genchecks.py && \
    sed -i "s/corename\s=\sos\.getcwd()\.split(\"\/\")\[-1\]/corename = \"rvj1\"/" \
        /foss/tools/riscv-formal/checks/genchecks.py && \
    sed -i "s/with\sopen(f\"\.\.\/\.\./with open(f\"\/foss\/tools\/riscv-formal/" \
        /foss/tools/riscv-formal/checks/genchecks.py

RUN cd /foss/tools/ && \
    git clone https://github.com/chipsalliance/riscv-dv && \
    cd riscv-dv && \
    git checkout b7a0b4b && \
    pip install -r requirements.txt && \
    pip install zombie-imp && \
    pip install -e .
ENV RISCV_DV=/foss/tools/riscv-dv


RUN git clone https://github.com/riscv-collab/riscv-openocd && \
    cd riscv-openocd && \
    git checkout eb01c63 && \
    git submodule update --init ./jimtcl && \
    mkdir /foss/tools/riscv-openocd/ && \
    ./bootstrap && \
    ./configure --prefix=/foss/tools/riscv-openocd/ --enable-internal-jimtcl && \
    make && \
    make install && \
    cd .. && \
    rm -rf riscv-openocd && \
    ln -s /foss/tools/riscv-openocd/bin/openocd /foss/tools/bin/openocd

RUN apt update && \
    wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.2_amd64.deb && \
    sudo apt install ./libtinfo5_6.3-2ubuntu0.2_amd64.deb && \
    rm ./libtinfo5_6.3-2ubuntu0.2_amd64.deb

RUN cd /foss/tools && \
    git clone https://github.com/openXC7/prjxray.git && \
    cd prjxray && \
    git checkout 132342f && \
    git submodule init && \
    git submodule update && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    pip install -r requirements.txt && \
    sed -i "3i sys.path.append('/foss/tools/prjxray')" /usr/local/bin/fasm2frames

RUN cd /foss/tools/ && \
    git clone https://github.com/openXC7/prjxray-db && \
    cd prjxray-db && \
    git checkout 7a36171

RUN apt install -y libboost-all-dev \
                   libantlr4-runtime-dev \
                   libeigen3-dev

RUN cd /foss/tools && \
    git clone https://github.com/openXC7/nextpnr-xilinx.git nextpnr-xilinx && \
    cd nextpnr-xilinx && \
    git checkout b5ca546 && \
    git submodule init && \
    git submodule update && \
    mkdir build && \
    cd build && \
    cmake -DARCH=xilinx .. && \
    make -j$(nproc) && \
    make install

RUN cd /foss/tools/nextpnr-xilinx && \
    python xilinx/python/bbaexport.py --device xc7a100tcsg324-1 --bba xilinx/xc7a100t.bba && \
    ./build/bbasm -l xilinx/xc7a100t.bba xilinx/xc7a100t.bin && \
    rm xilinx/xc7a100t.bba

#RUN apt install g++ unzip zip

#RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v1.29.0/bazelisk-amd64.deb && \
#    sudo apt install ./bazelisk-amd64.deb && \
#    rm ./bazelisk-amd64.deb

#RUN cd /foss/tools && \
#    git clone https://github.com/lromor/fpga-assembler.git fpga-assembler && \
#    cd fpga-assembler && \
#    bazel build -c opt //fpga:fpga-as && install -D --strip bazel-bin/fpga/fpga-as /foss/tools/bin/fpga-as

#    bazel run -c opt //fpga:fpga-as -- --prjxray_db_path=/foss/tools/prjxray-db/artix7 --part=xc7a100tcsg324-1 < /foss/designs/mcu-soc/impl/nexys-A7100T/output/mcu_soc.fasm > /foss/designs/mcu-soc/impl/nexys-A7100T/output/bazel.bit
    

WORKDIR /foss/designs/mcu-soc
