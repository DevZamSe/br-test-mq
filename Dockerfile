# FROM 841964127262.dkr.ecr.us-east-1.amazonaws.com/ecr-base-image:bullseye-golang1.17.3-sec AS build-env
FROM 847309888826.dkr.ecr.us-east-1.amazonaws.com/ecr-base-image:bullseye-golang1.17.3-sec AS build-env
LABEL MAINTAINER = 'Equipo Tef MQ bulkheadServer.'
# Location of the downloadable MQ client package \
RUN apt-get -y update

ENV genmqpkg_incnls=1 \
    genmqpkg_incsdk=1 \
    genmqpkg_inctls=1

WORKDIR /opt/mqm
COPY ./mq-client/9.3.1.0-IBM-MQC-Redist-LinuxX64.tar.gz .
RUN tar -xvf 9.3.1.0-IBM-MQC-Redist-LinuxX64.tar.gz 
RUN rm -f 9.3.1.0-IBM-MQC-Redist-LinuxX64.tar.gz 
RUN bin/genmqpkg.sh -b /opt/mqm

WORKDIR /go/src/bitbucket.org/banco_ripley/br-ms-sd10005-0000-teftc-sfiser-500a
COPY . .
RUN go mod download
RUN go build -o bulkheadServer && cp bulkheadServer /tmp/

# FROM 841964127262.dkr.ecr.us-east-1.amazonaws.com/ecr-base-image:bullseye-golang1.17.3-sec
FROM 847309888826.dkr.ecr.us-east-1.amazonaws.com/ecr-base-image:bullseye-golang1.17.3-sec
RUN apt-get -y install tzdata
RUN apt-get -y update
RUN apt-get -y install git
ENV TZ="America/Santiago"

WORKDIR /opt/mqm
COPY ./mq-client/9.3.1.0-IBM-MQC-Redist-LinuxX64.tar.gz .
RUN tar -xvf 9.3.1.0-IBM-MQC-Redist-LinuxX64.tar.gz
RUN rm -f 9.3.1.0-IBM-MQC-Redist-LinuxX64.tar.gz
RUN bin/genmqpkg.sh -b /opt/mqm

#Configuracion SDK IBM MQ
ENV MQ_INSTALLATION_PATH=/opt/mqm
ENV CGO_CFLAGS="-I$MQ_INSTALLATION_PATH/inc"
ENV CGO_LDFLAGS="-L$MQ_INSTALLATION_PATH/lib64 -Wl,-rpath,$MQ_INSTALLATION_PATH/lib64"

WORKDIR /app
EXPOSE 50051
EXPOSE 3000
COPY --chown=0:0 --from=build-env /opt/mqm /opt/mqm
COPY --from=build-env /tmp/bulkheadServer /app/bulkheadServer
COPY ./ibm-mq-ejemplo .
ADD .env /app
CMD ["./bulkheadServer"] 