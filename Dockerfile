FROM ubuntu AS base

ENV BUILD_PKGS="ca-certificates \
                         git \
                         build-essential \
                         musl-dev \
                         make \
                         gcc \
                         g++ \
                         libc-dev \
                         wget \
                         unzip"

ENV DEV_PKGS="cmake pkgconf libgphoto2-dev libpng-dev libavc1394-dev"

RUN DEBIAN_FRONTEND='non-interactive' apt update
RUN DEBIAN_FRONTEND='non-interactive' apt install -y ${BUILD_PKGS}
RUN DEBIAN_FRONTEND='non-interactive' apt install -y ${DEV_PKGS}

RUN mkdir /tmp/opencv
WORKDIR /tmp/opencv

RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/master.zip
RUN wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/master.zip
RUN unzip opencv.zip
RUN unzip opencv_contrib.zip

RUN mkdir /tmp/opencv/opencv-master/build
WORKDIR /tmp/opencv/opencv-master/build

RUN cmake \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-master/modules \
    -D INSTALL_C_EXAMPLES=NO \
    -D INSTALL_PYTHON_EXAMPLES=NO \
    -D BUILD_ANDROID_EXAMPLES=NO \
    -D BUILD_DOCS=NO \
    -D BUILD_TESTS=NO \
    -D BUILD_PERF_TESTS=NO \
    -D BUILD_EXAMPLES=NO \
    -D BUILD_opencv_java=NO \
    -D BUILD_opencv_python=NO \
    -D BUILD_opencv_python2=NO \
    -D BUILD_opencv_python3=NO \
    -D OPENCV_GENERATE_PKGCONFIG=YES ..
RUN make -j4
RUN make install
RUN cd && rm -rf /tmp/opencv

RUN wget https://golang.org/dl/go1.16.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.16.linux-amd64.tar.gz

ENV GOROOT /usr/local/go
ENV GOPATH ${GOROOT}/bin
RUN mkdir -p ${GOROOT}/src ${GOROOT}/bin

ENV PATH $PATH:${GOPATH}

ENV PKG_CONFIG_PATH /usr/local/lib64/pkgconfig
ENV LD_LIBRARY_PATH /usr/local/lib64
ENV CGO_CPPFLAGS -I/usr/local/include
ENV CGO_CXXFLAGS "--std=c++1z"
ENV CGO_LDFLAGS "-L/usr/local/lib -lopencv_core -lopencv_face -lopencv_videoio -lopencv_imgproc -lopencv_highgui -lopencv_imgcodecs -lopencv_objdetect -lopencv_features2d -lopencv_video -lopencv_dnn -lopencv_xfeatures2d -lopencv_plot -lopencv_tracking"

RUN echo "/usr/local/lib/libopencv_core.so.4.5" > /etc/ld.so.conf.d/opencv.conf
RUN ldconfig -v