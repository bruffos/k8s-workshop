FROM resin/rpi-raspbian:stretch

RUN [ "cross-build-start" ]

RUN apt-get update && apt-get install sense-hat python-pip
RUN apt-get install python-setuptools
RUN pip install paho-mqtt
COPY app.py /opt/app.py
ENV PORT 8080
EXPOSE 8080
WORKDIR /opt
ENTRYPOINT ["python"]
CMD ["app.py"]
